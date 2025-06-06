# frozen_string_literal: true

class CreateOpportunity
  Result = Struct.new(:success?, :opportunity, :errors, keyword_init: true)

  def self.call(params:)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  def call
    opportunity = Opportunity.new(@params)

    if opportunity.save
      Result.new(success?: true, opportunity: opportunity)
    else
      Result.new(success?: false, errors: opportunity.errors.full_messages)
    end
  end
end
