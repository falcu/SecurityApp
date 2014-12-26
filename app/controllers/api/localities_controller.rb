class Api::LocalitiesController < ApiController
  include ApiHelper
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_locality
  before_action :set_group
  before_action :set_notifier_builder
  before_action :check_locality

  def notify_locality
    frequency = @current_user.frequencies.select { |s| s.locality_id == @locality.id }.first

    if frequency
      frequency.value = frequency.value + 1
    else
      frequency = @current_user.frequencies.build(locality_id: @locality.id, value: 1)
    end

    if is_insecure && @group
      notify_current_locality
    end

    if frequency.save
      render_json({message: "Done"},200)
    else
      render_json({error: "Unable to save frequency"}, 400)
    end
  end

  def set_secure_locality
    add_locality(@current_user.custom_secure_localities)
    remove_locality(@current_user.custom_insecure_localities)
    if @current_user.save
      render_json({message: "Done"},200)
    end
  end

  def set_insecure_locality
    add_locality(@current_user.custom_insecure_localities)
    remove_locality(@current_user.custom_secure_localities)
    if @current_user.save
      render_json({message: "Done"},200)
    end
  end

  private
  def add_locality(localities)
    localities << @locality unless localities.include?(@locality)
  end

  private
  def remove_locality(localities)
    localities.delete(@locality) if localities.include?(@locality)
  end

  private
  def set_group
    if params[:group_id]
      @group = Group.find(params[:group_id])
    end
  end

  private
  def set_locality
    locality_name = get_locality_name
    if locality_name
      @locality = Locality.find_by_name(locality_name)
    else
      render_json({error: "Invalid coordinates"}, 400)
    end
  end

  private
  def set_notifier_builder
    @builder = NotifierBuilder.new
  end

  private
  def notify_current_locality
    reg_ids = registration_ids(@group, [@current_user])
    message = @current_user.name << " entered " << @locality.name << " which is considered unsecured"
    @builder.notifier.notify(reg_ids: reg_ids, :data => {message: message, location: location_url(params)})
  end

  private
  def get_locality_name
    params[:locality_name] || find_locality(params[:latitude], params[:longitude])
  end

  private
  def check_locality
    if @locality.nil?
      render_json({error: "Unknown locality"},400)
    end
  end

  private
  def is_insecure
    (@locality.insecure && !@current_user.custom_secure_localities.include?(@locality)) || @current_user.custom_insecure_localities.include?(@locality)
  end

end
