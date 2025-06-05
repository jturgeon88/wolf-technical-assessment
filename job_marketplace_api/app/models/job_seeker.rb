# frozen_string_literal: true

class JobSeeker < ApplicationRecord
  has_many :job_applications, dependent: :destroy
end
