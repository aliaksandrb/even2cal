class ErrorsController < ApplicationController
  layout 'error'

  def error_404
    @vk_authorized = vk_authorized
    @google_authorized = google_authorized
    @not_found_path = params[:not_found]
  end

  def error_500
  end
end
