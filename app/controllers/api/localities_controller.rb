class Api::LocalitiesController < ApiController
  include ApiHelper
  include Api::LocalitiesHelper

  before_action :set_locality, except: [:create]

  def notify_locality
      frequency = @current_user.frequencies.select{|s| s.locality_id == @locality.id}.first

      if frequency
        frequency.value = frequency.value + 1
      else
        frequency = @current_user.frequencies.build(user_id: @current_user.id, locality_id: @locality.id,value: 1)
      end

      if frequency.save
        respond_to do |format|
          format.json {render json: {message: 'Done'}, status: 200}
        end
      else
        respond_bad_json('Unable to save frequency')
      end


  end

  private
  def set_locality
    locality_name = find_locality(params[:latitude],params[:longitude])
    @locality = Locality.find_by_name(locality_name)
  end

end
