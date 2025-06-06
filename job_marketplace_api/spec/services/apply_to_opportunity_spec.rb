# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplyToOpportunity, type: :service do
  let!(:client) { Client.create!(name: "ACME", email: "client@example.com") }
  let!(:opportunity) { Opportunity.create!(title: "Engineer", description: "Stuff", salary: 100000, location: "Remote", employment_type: "full-time", remote: true, client: client) }
  let!(:job_seeker) { JobSeeker.create!(name: "Josh Dev", email: "josh@example.com") }

  before do
    ActionMailer::Base.deliveries.clear
  end

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

  context "with valid inputs" do
    it "returns success and creates a job application" do
      result = described_class.call(opportunity_id: opportunity.id, job_seeker_id: job_seeker.id)

      expect(result.success?).to eq(true)
      expect(result.job_application).to be_persisted
      expect(result.errors).to be_nil
    end

    it "enqueues an ApplicationNotificationWorker job" do
      Sidekiq::Worker.clear_all

      expect {
        described_class.call(opportunity_id: opportunity.id, job_seeker_id: job_seeker.id)
      }.to change(ApplicationNotificationWorker.jobs, :size).by(1)

      job_args = ApplicationNotificationWorker.jobs.last['args']
      expect(job_args[0]).to be_a(Integer)
      expect(job_args[1]).to eq(opportunity.title)
      expect(job_args[2]).to eq(job_seeker.email)
      expect(job_args[3]).to eq(client.email)
    end

    it "sends a new application notification email through the worker" do
      Sidekiq::Testing.inline! do
        expect {
          described_class.call(opportunity_id: opportunity.id, job_seeker_id: job_seeker.id)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(client.email)
      expect(email.subject).to eq("New Application for '#{opportunity.title}'")
      expect(email.body.encoded).to include("Job Seeker Email: #{job_seeker.email}")
      expect(email.body.encoded).to include("A new application has been submitted for your opportunity: #{opportunity.title}")
    end
  end
end
