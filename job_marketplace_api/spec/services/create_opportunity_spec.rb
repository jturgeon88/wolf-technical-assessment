# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateOpportunity, type: :service do
  let!(:client) { Client.create!(name: "Test Client", email: "client@example.com") }

  let(:valid_params) do
    {
      title: "Backend Developer",
      description: "Write solid Rails code",
      salary: 120_000,
      location: "Remote",
      employment_type: "full-time",
      remote: true,
      client_id: client.id
    }
  end

  it "creates an opportunity with valid params" do
    result = described_class.call(params: valid_params)

    expect(result.success?).to be true
    expect(result.opportunity).to be_persisted
    expect(result.opportunity.title).to eq("Backend Developer")
    expect(result.errors).to be_nil
  end

  it "returns errors if required fields are missing" do
    result = described_class.call(params: valid_params.except(:title))

    expect(result.success?).to be false
    expect(result.opportunity).to be_nil
    expect(result.errors).to include("Title can't be blank")
  end

  it "returns errors if client_id is invalid" do
    bad_params = valid_params.merge(client_id: -1)

    result = described_class.call(params: bad_params)

    expect(result.success?).to be false
    expect(result.errors).to include("Client must exist")
  end
end
