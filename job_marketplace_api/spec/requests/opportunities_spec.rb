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
end
