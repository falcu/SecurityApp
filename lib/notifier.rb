class Notifier

  def app_name
    @app_name
  end

  def app_name=(value)
    @app_name = value
  end

  def notify(args)
    validate_args(args)
    notification = Rpush::Gcm::Notification.new
    appliaction_name = args[:app_name] || app_name
    notification.app = Rpush::Gcm::App.find_by_name(appliaction_name)
    notification.registration_ids = args[:reg_ids]
    notification.data = args[:data]
    notification.save!
  end

  private
  def validate_args(args)
    if args[:app_name].nil? && app_name.nil?
      raise ArgumentError.new("app_name missing")
    end
    if args[:reg_ids].nil?
      raise ArgumentError.new("reg_ids missing")
    end
    if args[:data].nil?
      raise ArgumentError.new("data missing")
    end
  end


end