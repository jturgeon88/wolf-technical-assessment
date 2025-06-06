# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplyToOpportunity, type: :service do
  let!(:client) { Client.create!(name: "ACME", email: "client@example.com") }
  let!(:opportunity) { Opportunity.create!(title: "Engineer", description: "Stuff", salary: 100000, location: "Remote", employment_type: "full-time", remote: true, client: client) }
  let!(:job_seeker) { JobSeeker.create!(name: "Josh Dev", email: "josh@example.com") }

  context "with valid inputs" do
    it "returns success and creates a job application" do
      result = described_class.call(opportunity_id: opportunity.id, job_seeker_id: job_seeker.id)

      expect(result.success?).to eq(true)
      expect(result.job_application).to be_persisted
      expect(result.errors).to be_nil
    end
  end

  context "when opportunity is missing" do
    it "returns error result" do
      result = described_class.call(opportunity_id: -1, job_seeker_id: job_seeker.id)

      expect(result.success?).to eq(false)
      expect(result.job_application).to be_nil
      expect(result.errors).to include("Invalid opportunity or job seeker")
    end
  end

  context "when job_seeker is missing" do
    it "returns error result" do
      result = described_class.call(opportunity_id: opportunity.id, job_seeker_id: -1)

      expect(result.success?).to eq(false)
      expect(result.job_application).to be_nil
      expect(result.errors).to include("Invalid opportunity or job seeker")
    end
  end

  context "when saving the application fails" do
    it "returns validation errors" do
      allow(JobApplication).to receive(:new).and_return(JobApplication.new)

      result = described_class.call(opportunity_id: opportunity.id, job_seeker_id: job_seeker.id)

      expect(result.success?).to eq(false)
      expect(result.errors).to include("Opportunity must exist").or include("Job seeker must exist")
    end
  end
end
