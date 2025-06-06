# frozen_string_literal: true

class OpportunitiesController < ApplicationController

  # GET /opportunities
  # Returns a paginated list of opportunities, optionally filtered by title search query.
  #
  # @param q [String] Optional search query to filter opportunities by title.
  # @param items [Integer] Optional number of items per page (default is 10).
  # @return [JSON] A JSON response containing the list of opportunities and pagination info.
  def index
    opportunities = Opportunity.includes(:client).order(created_at: :desc)
    opportunities = opportunities.where("title ILIKE ?", "%#{params[:q]}%") if params[:q].present?

    pagy, paginated_opps = pagy(opportunities, items: params[:items]&.to_i || 10)

    render json: {
      opportunities: paginated_opps.map do |opp|
        opp.as_json(include: { client: { only: [:id, :name] } })
      end,
      pagination: {
        page: pagy.page,
        items: pagy.vars[:items],
        total: pagy.count,
        pages: pagy.pages
      }
    }
  end

  # POST /opportunities
  # Creates a new opportunity on behalf of a client.
  #
  # @param opportunity [Hash] Required opportunity attributes including client_id.
  # @return [JSON] The created opportunity or errors if creation fails.
  def create
    result = CreateOpportunity.call(params: opportunity_params)

    if result.success?
      render json: result.opportunity, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  # POST /opportunities/:id/apply
  # Allows a job seeker to apply for an opportunity.
  #
  # @param id [Integer] The ID of the opportunity to apply for.
  # @param application [Hash] Contains job_seeker_id to apply with.
  # @return [JSON] The created job application or errors if application fails.
  def apply
    result = ApplyToOpportunity.call(
      opportunity_id: params[:id],
      job_seeker_id: application_params[:job_seeker_id]
    )

    if result.success?
      render json: result.job_application, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => e
    render json: { errors: [e.message] }, status: :unprocessable_entity
  end



  private

  def opportunity_params
    params.require(:opportunity).permit(
      :title,
      :description,
      :salary,
      :location,
      :employment_type,
      :remote,
      :client_id
    )
  end

  def application_params
    params.require(:application).permit(:job_seeker_id)
  end
end
