# frozen_string_literal: true

class ApplyToOpportunity
  Result = Struct.new(:success?, :job_application, :errors, keyword_init: true)

  def self.call(opportunity_id:, job_seeker_id:)
    new(opportunity_id, job_seeker_id).call
  end

  def initialize(opportunity_id, job_seeker_id)
    @opportunity_id = opportunity_id
    @job_seeker_id = job_seeker_id
  end

  def call
    opportunity = Opportunity.find_by(id: @opportunity_id)
    job_seeker = JobSeeker.find_by(id: @job_seeker_id)

    unless opportunity && job_seeker
      return Result.new(success?: false, errors: ["Invalid opportunity or job seeker"])
    end

    application = JobApplication.new(opportunity: opportunity, job_seeker: job_seeker)

    if application.save
      Result.new(success?: true, job_application: application)
    else
      Result.new(success?: false, errors: application.errors.full_messages)
    end
  end
end
