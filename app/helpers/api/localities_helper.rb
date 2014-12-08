module Api::LocalitiesHelper
  include ApiHelper

  class GoogleMapsFinder
    GOOGLE_MAPS = "http://maps.googleapis.com/maps/api/geocode/json?latlng=COORDINATES&sensor=true_or_false"
    def find_locality(latitude,longitude)
      coordinates = latitude + "," + longitude
      uri = URI.parse(GOOGLE_MAPS.gsub("COORDINATES",coordinates))
      response = Net::HTTP.get(uri)
      json = JSON.parse(response)
      if(json['results'][0])
        json['results'][0]['address_components'][2]['long_name']
      end
    end
  end

  def finder
    @finder ||= GoogleMapsFinder.new
  end

  def find_locality(latitude,longitude)
    finder.find_locality(latitude,longitude)
  end
end
