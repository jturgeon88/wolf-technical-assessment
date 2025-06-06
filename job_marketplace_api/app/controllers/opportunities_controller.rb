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
end
