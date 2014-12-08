module LocalitiesHelper
  def notify_locality(latitude,longitude)
    put :notify_locality, {latitude: latitude, longitude: longitude, :format => "json"}
  end
  RSpec.configure do |c|
    c.include LocalitiesHelper, type: :controller
  end
end