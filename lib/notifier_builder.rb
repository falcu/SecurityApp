class NotifierBuilder

  def initialize
    @app_name = "android_app"
  end

  def notifier
    notification = Notifier.new
    notification.app_name = @app_name
    notification
  end
end