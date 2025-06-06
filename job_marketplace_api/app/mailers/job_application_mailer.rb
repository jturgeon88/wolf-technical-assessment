# frozen_string_literal: true

class JobApplicationMailer < ApplicationMailer
  def new_application_notification(job_application_id, opportunity_title, job_seeker_email, client_email)
    @job_application_id = job_application_id
    @opportunity_title = opportunity_title
    @job_seeker_email = job_seeker_email

    mail(
      to: client_email,
      subject: "New Application for '#{@opportunity_title}'"
    ) do |format|
      format.text do
        "Dear Client,\n\n" \
        "A new application has been submitted for your opportunity: #{@opportunity_title}.\n\n" \
        "Job Application ID: #{@job_application_id}\n" \
        "Job Seeker Email: #{@job_seeker_email}\n\n" \
        "Please log in to your dashboard to view the application details.\n\n" \
        "Best regards,\n" \
        "The Job Marketplace Team"
      end
    end
  end
end
