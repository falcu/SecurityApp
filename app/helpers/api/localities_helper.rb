module Api::LocalitiesHelper
  GOOGLE_MAPS = "http://maps.googleapis.com/maps/api/geocode/json?latlng=COORDINATES&sensor=true_or_false"
  def find_locality(latitude,longitude)
    coordinates = latitude + "," + longitude
    uri = URI.parse(GOOGLE_MAPS.gsub("COORDINATES",coordinates))
    response = Net::HTTP.get(uri)
    json = JSON.parse(response)
    json['results'][0]['address_components'][2]['long_name']
  end
end
