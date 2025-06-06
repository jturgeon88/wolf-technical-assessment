# frozen_string_literal: true

class ApplicationNotificationWorker
  include Sidekiq::Worker

  sidekiq_options retry: 3

  def perform(job_application_id, opportunity_title, job_seeker_email, client_email)
    # Send email notification to client about the new job application
    JobApplicationMailer.new_application_notification(
      job_application_id,
      opportunity_title,
      job_seeker_email,
      client_email
    ).deliver_now

    Rails.logger.info "Sidekiq Worker: Processing complete and email sent for Job Application ID: #{job_application_id}"
  rescue => e
    Rails.logger.error "Sidekiq Worker: Error processing job application #{job_application_id}: #{e.message}"
    raise e
  end
end
