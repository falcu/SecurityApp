module ApiHelpers
  def create_app_for_push_notification
    app = Rpush::Gcm::App.new
    app.name = "android_app"
    app.auth_key = "123"
    app.connections = 1
    app.save!
  end

end
RSpec.configure do |c|
  c.include ApiHelpers, type: :controller
end

