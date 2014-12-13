class Notifier

  def app_name
    @app_name
  end
  def app_name=(value)
    @app_name = value
  end

  def notify(args)
    notification = Rpush::Gcm::Notification.new
    appliaction_name = args[:app_name] || app_name
    notification.app = Rpush::Gcm::App.find_by_name(appliaction_name)
    notification.registration_ids = ["token", args[:reg_ids]]
    notification.data = { message: args[:message], location: args[:location_url] }
    notification.save!
  end

end