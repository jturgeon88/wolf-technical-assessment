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
end
