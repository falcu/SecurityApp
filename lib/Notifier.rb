class Notifier

  def notify(args)
    notification = Rpush::Gcm::Notification.new
    notification.app = Rpush::Gcm::App.find_by_name(args[:app_name])
    notification.registration_ids = ["token", args[:reg_ids]]
    notification.data = { message: args[:message], location: args[:location_url] }
    notification.save!
  end
end