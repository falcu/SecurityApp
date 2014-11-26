class ApiController < ActionController::Base
  before_action :check_token

  protected
  def check_token
    authenticate_or_request_with_http_token do |token, options|
      User.find_by(token: token)
    end
  end
end