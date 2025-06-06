# frozen_string_literal: true

class JobSeeker < ApplicationRecord
  has_many :job_applications, dependent: :destroy
  has_many :opportunities, through: :job_applications

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
