# frozen_string_literal: true

class Opportunity < ApplicationRecord
  belongs_to :client
  has_many :applications, class_name: "JobApplication", dependent: :destroy

  validates :title, :description, :salary, presence: true
end
