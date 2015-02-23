class Api::LocalitiesController < ApiController
  include ApiHelper
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_locality, only: [:notify_locality, :set_secure_locality, :set_insecure_locality]
  before_action :set_group, only: [:notify_locality]
  before_action :set_notifier_builder, only: [:notify_locality]
  before_action :check_locality, only: [:notify_locality, :set_secure_locality, :set_insecure_locality]

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
      message = "You set " + @locality.name + " as a secure locality"
      render_json({message: message, type: "set_secure_locality"},200)
    end
  end

  def set_insecure_locality
    add_locality(@current_user.custom_insecure_localities)
    remove_locality(@current_user.custom_secure_localities)
    if @current_user.save
      message = "You set " + @locality.name + " as an insecure locality"
      render_json({message: message, type: "set_insecure_locality"},200)
    end
  end

  def get_localities
    localities_json = localities_to_json(Locality.all)
    render_json({message: "Localities list", type: "localities", localities_info: localities_json },200)
  end

  def get_secure_localities
    localities_json = localities_to_json(@current_user.custom_secure_localities)
    render_json({message: "Secured localities list", type: "secured_localities", localities_info: localities_json },200)
  end

  def get_insecure_localities
    localities_json = localities_to_json(@current_user.custom_insecure_localities)
    render_json({message: "Secured localities list", type: "secured_localities", localities_info: localities_json },200)
  end

  def get_classified_localities
    unclassified_json = localities_to_json(Locality.all - @current_user.custom_secure_localities - @current_user.custom_insecure_localities)
    secure_json = localities_to_json(@current_user.custom_secure_localities)
    insecure_json = localities_to_json(@current_user.custom_insecure_localities)
    render_json({message: "classified localities list", type: "classified_localities",
                 :localities_info=>{unclassified: unclassified_json, secure: secure_json, insecure: insecure_json}},200)
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
    @locality = get_locality
      if @locality.nil?
      render_json({error: "Invalid coordinates"}, 400)
    end
  end

  private
  def set_notifier_builder
    @builder = NotifierBuilder.new
  end

  private
  def notify_current_locality
    reg_ids = registration_ids_of_group_excluding(@group, [@current_user])
    message = @current_user.name << " entered " << @locality.name << " which is considered unsecured"
    @builder.notifier.notify(reg_ids: reg_ids, :data => {message: message, location: location_url(params), type: "notify_unsecure_location"})
  end

  private
  def get_locality_name
    params[:locality_name] || find_locality(params[:latitude], params[:longitude])
  end

  private
  def get_locality
    if params[:id]
      locality = Locality.find(params[:id])
    else
      locality_name = get_locality_name
      if locality_name
        locality = Locality.find_by_name(locality_name)
      end
    end
    locality
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

  private
  def localities_to_json(localities)
    localities.collect { |locality| locality.as_json(:only => [:id, :name]) }
  end

end
