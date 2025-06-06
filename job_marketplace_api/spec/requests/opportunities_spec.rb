# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Opportunities API", type: :request do
  describe "GET /opportunities" do
    let!(:client) { Client.create!(name: "ACME Corp", email: "acme@example.com") }

    before do
      Opportunity.create!(
        title: "DevOps Engineer",
        description: "Deploy and automate",
        salary: 100_000,
        location: "Remote",
        employment_type: "full-time",
        remote: true,
        client: client
      )

      Opportunity.create!(
        title: "Product Designer",
        description: "UX and UI focus",
        salary: 120_000,
        location: "Austin, TX",
        employment_type: "contract",
        remote: false,
        client: client
      )
    end

    it "returns all opportunities with client included" do
      get "/opportunities"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json["opportunities"].length).to eq(2)
      expect(json["opportunities"][0]).to include("client")
    end

    it "paginates the results" do
      get "/opportunities", params: { items: 1 }

      json = JSON.parse(response.body)
      expect(json["opportunities"].length).to eq(1)
      expect(json["pagination"]).to include("total" => 2, "items" => 1)
    end

    it "filters by title with search param" do
      get "/opportunities", params: { q: "DevOps" }

      json = JSON.parse(response.body)
      expect(json["opportunities"].length).to eq(1)
      expect(json["opportunities"].first["title"]).to eq("DevOps Engineer")
    end
  end

  describe "POST /opportunities" do
    let!(:client) { Client.create!(name: "ACME Corp", email: "acme@example.com") }

    let(:valid_params) do
      {
        opportunity: {
          title: "Ruby Engineer",
          description: "Write clean Ruby code",
          salary: 120_000,
          location: "NYC",
          employment_type: "full-time",
          remote: false,
          client_id: client.id
        }
      }
    end

    it "creates an opportunity with valid params" do
      post "/opportunities", params: valid_params.to_json, headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["title"]).to eq("Ruby Engineer")
      expect(Opportunity.count).to eq(1)
    end

    it "returns 422 if required fields are missing" do
      invalid = valid_params.deep_dup
      invalid[:opportunity].delete(:title)

      post "/opportunities", params: invalid.to_json, headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Title can't be blank")
    end

    it "returns 422 if client_id is invalid" do
      bad_client = valid_params.deep_dup
      bad_client[:opportunity][:client_id] = 9999

      post "/opportunities", params: bad_client.to_json, headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Client must exist")
    end
  end

  describe "POST /opportunities/:id/apply" do
    let!(:client) { Client.create!(name: "ACME Corp", email: "acme@example.com") }
    let!(:opportunity) do
      Opportunity.create!(
        title: "QA Engineer",
        description: "Test everything twice",
        salary: 90_000,
        location: "Remote",
        employment_type: "full-time",
        remote: true,
        client: client
      )
    end
    let!(:job_seeker) { JobSeeker.create!(name: "Josh Dev", email: "josh@example.com") }

    it "creates a job application successfully" do
      post "/opportunities/#{opportunity.id}/apply",
        params: { application: { job_seeker_id: job_seeker.id } }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["job_seeker_id"]).to eq(job_seeker.id)
      expect(json["opportunity_id"]).to eq(opportunity.id)
    end

    it "returns 422 if job_seeker_id is missing" do
      post "/opportunities/#{opportunity.id}/apply",
        params: { application: {} }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("param is missing or the value is empty: application")
    end

    it "returns 422 if job_seeker does not exist" do
      post "/opportunities/#{opportunity.id}/apply",
        params: { application: { job_seeker_id: 999 } }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Invalid opportunity or job seeker")
    end

    it "returns 422 if opportunity does not exist" do
      post "/opportunities/999/apply",
        params: { application: { job_seeker_id: job_seeker.id } }.to_json,
        headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to include("Invalid opportunity or job seeker")
    end
  end

  context "with caching enabled" do
    let!(:client) { Client.create!(name: "Cache Client", email: "cache_client@example.com") }
    let!(:opportunity_1) do
      Opportunity.create!(
        title: "Cached Opportunity 1",
        description: "This is a test opportunity for caching",
        salary: 100_000,
        location: "Remote",
        employment_type: "full-time",
        remote: true,
        client: client
      )
    end
    let!(:opportunity_2) do
      Opportunity.create!(
        title: "Cached Opportunity 2",
        description: "Another test opportunity for caching",
        salary: 110_000,
        location: "On-site",
        employment_type: "contract",
        remote: false,
        client: client
      )
    end

    before do
      Rails.cache.clear
    end

    # Helper method to capture SQL queries
    def capture_sql_queries
      sql_queries = []
      ActiveSupport::Notifications.subscribed(
        lambda do |_name, _start, _finish, _id, payload|
          sql_queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end,
        "sql.active_record"
      ) do
        yield
      end
      sql_queries
    end

    it "performs database queries on the first request (cache miss)" do
      sql_queries = capture_sql_queries { get "/opportunities" }

      # Expect to see Opportunity Load and Client Load queries
      expect(sql_queries).to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries).to include(/SELECT "clients"\..* FROM "clients"/)
      # More precise counts
      expect(sql_queries.grep(/SELECT "opportunities"\..* FROM "opportunities"/).count).to eq(1)
      expect(sql_queries.grep(/SELECT "clients"\..* FROM "clients"/).count).to eq(1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["opportunities"].length).to eq(2)
    end

    it "does not perform database queries on subsequent identical requests (cache hit)" do
      # First request populates cache
      get "/opportunities"

      sql_queries = capture_sql_queries { get "/opportunities" }

      # For the second request, expect NOT to see Opportunity Load or Client Load
      # but still expect the pagy count query.
      expect(sql_queries).not_to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries).not_to include(/SELECT "clients"\..* FROM "clients"/)
      expect(sql_queries).to include(/SELECT COUNT\(\*\) FROM "opportunities"/)

      expect(sql_queries.grep(/SELECT "opportunities"\..* FROM "opportunities"/).count).to eq(0)
      expect(sql_queries.grep(/SELECT "clients"\..* FROM "clients"/).count).to eq(0)
      expect(sql_queries.grep(/SELECT COUNT\(\*\) FROM "opportunities"/).count).to eq(1)


      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["opportunities"].length).to eq(2)
    end

    it "uses a different cache key for different query parameters" do
      # First request for query 1
      get "/opportunities", params: { q: "Cached Opportunity 1" }

      # Making the first request for a distinct query should still hit the DB
      sql_queries_q2_miss = capture_sql_queries do
        get "/opportunities", params: { q: "Cached Opportunity 2" }
      end
      expect(sql_queries_q2_miss).to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_q2_miss).to include(/SELECT "clients"\..* FROM "clients"/)

      # Second request for query 1 should hit the cache now
      sql_queries_q1_hit = capture_sql_queries do
        get "/opportunities", params: { q: "Cached Opportunity 1" }
      end
      expect(sql_queries_q1_hit).not_to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_q1_hit).not_to include(/SELECT "clients"\..* FROM "clients"/)

      # Second request for query 2 should hit the cache now
      sql_queries_q2_hit = capture_sql_queries do
        get "/opportunities", params: { q: "Cached Opportunity 2" }
      end
      expect(sql_queries_q2_hit).not_to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_q2_hit).not_to include(/SELECT "clients"\..* FROM "clients"/)

      expect(response).to have_http_status(:ok)
    end

    it "caches based on pagination parameters" do
      # First request for page 1, items 1
      sql_queries_p1_i1_miss = capture_sql_queries do
        get "/opportunities", params: { page: 1, items: 1 }
      end
      expect(sql_queries_p1_i1_miss).to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_p1_i1_miss).to include(/SELECT "clients"\..* FROM "clients"/)

      # Second request for page 1, items 1 (cache hit)
      sql_queries_p1_i1_hit = capture_sql_queries do
        get "/opportunities", params: { page: 1, items: 1 }
      end
      expect(sql_queries_p1_i1_hit).not_to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_p1_i1_hit).not_to include(/SELECT "clients"\..* FROM "clients"/)

      # First request for page 2, items 1 (cache miss)
      sql_queries_p2_i1_miss = capture_sql_queries do
        get "/opportunities", params: { page: 2, items: 1 }
      end
      expect(sql_queries_p2_i1_miss).to include(/SELECT "opportunities"\..* FROM "opportunities"/)
      expect(sql_queries_p2_i1_miss).to include(/SELECT "clients"\..* FROM "clients"/)
    end
  end
end
