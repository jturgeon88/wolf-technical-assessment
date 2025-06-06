# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobApplicationMailer, type: :mailer do
  describe "new_application_notification" do
    let(:job_application_id) { 123 }
    let(:opportunity_title) { "Senior Software Engineer" }
    let(:job_seeker_email) { "job_seeker@example.com" }
    let(:client_email) { "client@example.com" }

    let(:mail) { JobApplicationMailer.new_application_notification(
      job_application_id,
      opportunity_title,
      job_seeker_email,
      client_email
    )}

    it "renders the headers" do
      expect(mail.subject).to eq("New Application for 'Senior Software Engineer'")
      expect(mail.to).to eq(["client@example.com"])
      expect(mail.from).to eq([ENV.fetch('GMAIL_USERNAME')])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Dear Client,")
      expect(mail.body.encoded).to include("A new application has been submitted for your opportunity: Senior Software Engineer.")
      expect(mail.body.encoded).to include("Job Application ID: 123")
      expect(mail.body.encoded).to include("Job Seeker Email: job_seeker@example.com")
      expect(mail.body.encoded).to include("Please log in to your dashboard to view the application details.")
    end
  end
end
