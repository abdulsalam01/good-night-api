class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  PAGE_SIZE = 5
  FEED_PAGE_SIZE = 10

  private

  def render_not_found
    render json: { error: "Not Found" }, status: :not_found
  end
end
