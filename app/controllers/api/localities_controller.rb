class Api::LocalitiesController <  Api::GroupsAuthorizationController
  include ApiHelper
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_locality
  before_action :set_group

  def notify_locality
      frequency = @current_user.frequencies.select{|s| s.locality_id == @locality.id}.first

      if frequency
        frequency.value = frequency.value + 1
      else
        frequency = @current_user.frequencies.build(locality_id: @locality.id,value: 1)
      end

      if @locality.unsecure && @group
        notify_current_locality
      end

      if frequency.save
        respond_to do |format|
          format.json {render json: {message: 'Done'}, status: 200}
        end
      else
        respond_bad_json('Unable to save frequency',400)
      end

  end

  private
  def set_locality
    locality_name = find_locality(params[:latitude],params[:longitude])
    if locality_name
    @locality = Locality.find_by_name(locality_name)
    else
      respond_bad_json("Invalid coordinates",400)
      end
  end

  private
  def notify_current_locality
    reg_ids = registration_ids(@group,@current_user)
    message = @current_user.name << " entered " << @locality.name <<  " which is considered unsecured"
    notification = Rpush::Gcm::Notification.new
    notification.app = Rpush::Gcm::App.find_by_name("android_app")
    notification.registration_ids = ["token", reg_ids]
    notification.data = { message: message, location: location_url(params) }
    notification.save!
  end

  private
  def set_group
    if params[:group_id]
    @group = Group.find(params[:group_id])
    end
  end


end
