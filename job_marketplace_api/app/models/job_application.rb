# frozen_string_literal: true

class JobApplication < ApplicationRecord
  belongs_to :job_seeker
  belongs_to :opportunity

  enum status: {
    submitted: "submitted",
    viewed: "viewed",
    rejected: "rejected",
    hired: "hired"
  }
end
