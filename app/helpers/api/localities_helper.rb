module Api::LocalitiesHelper
  include ApiHelper

  class GoogleMapsFinder
    DEFAULT_ZOOM = "20"
    GOOGLE_MAPS_API_URL = "http://maps.googleapis.com/maps/api/geocode/json?latlng=COORDINATES&sensor=true_or_false"
    GOOGLE_MAPS = "https://www.google.com.ar/maps/@COORDINATES,ZOOMz"

    def find_locality(latitude,longitude)
      coordinates = latitude + "," + longitude
      uri = URI.parse(GOOGLE_MAPS_API_URL.gsub("COORDINATES",coordinates))
      response = Net::HTTP.get(uri)
      json = JSON.parse(response)
      if(json['results'][0])
        json['results'][0]['address_components'][2]['long_name']
      end
    end

    def location_url(*args)
      coordinates = args[0][:latitude] + "," + args[0][:longitude]
      zoom = args[0][:zoom] || DEFAULT_ZOOM
      GOOGLE_MAPS.gsub("COORDINATES",coordinates).gsub("ZOOM",zoom)
    end
  end

  def finder
    @finder ||= GoogleMapsFinder.new
  end

  def find_locality(latitude,longitude)
    finder.find_locality(latitude,longitude)
  end

  def location_url(params)
    finder.location_url(latitude: params[:latitude], longitude: params[:longitude], zoom: params[:zoom])
  end
end
