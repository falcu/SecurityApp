class Api::LocalitiesController < ApiController
  include ApiHelper
  include Api::LocalitiesHelper
  include Api::GroupsHelper
  include Api::UsersHelper

  before_action :set_current_locality, only: [:notify_locality, :set_locality_classification]
  before_action :set_group, only: [:notify_locality]
  before_action :set_notifier_builder, only: [:notify_locality]
  before_action :check_locality, only: [:notify_locality, :set_locality_classification]

  def notify_locality
    frequency = @current_user.frequencies.select { |s| s.locality_id == @locality.id }.first

    if frequency
      frequency.value = frequency.value + 1
    else
      frequency = @current_user.frequencies.build(locality_id: @locality.id, value: 1)
    end

    if is_insecure && @group && @group.members.any?
      notify_current_locality
    end

    if frequency.save
      render_json({message: "Done"},200)
    else
      render_json({error: "Unable to save frequency"}, 400)
    end
  end

  def set_locality_classification
    if locality_classification.eql?("secure")
      set_secure_locality
    elsif locality_classification.eql?("insecure")
      set_insecure_locality
    elsif locality_classification.eql?("unclassified")
      set_locality_with_no_custom_classification
    else
      render_json({error: locality_classification + " is not a valid classification for a locality"},401)
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
  def set_current_locality
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
    default_message = @current_user.name + " entered " + @locality.name + " which is considered insecure"
    user_message = params[:message] || default_message
    notification_message = @current_user.name + " has sent a notification"
    @builder.notifier.notify(reg_ids: reg_ids, :data =>
                                                 {message: notification_message,
                                                  :locality_notification_info=>{message: user_message, location: location_url(params), sender: users_to_json([@current_user]).first },
                                                  type: "notification_insecure_location"})
  end

  private
  def set_secure_locality
    add_locality(@current_user.custom_secure_localities)
    remove_locality(@current_user.custom_insecure_localities)
    if @current_user.save
      message = "You set " + @locality.name + " as a secure locality"
      render_json({locality: localities_to_json([@locality]).first,message: message, type: "set_secure_locality"},200)
    end
  end

  private
  def set_insecure_locality
    add_locality(@current_user.custom_insecure_localities)
    remove_locality(@current_user.custom_secure_localities)
    if @current_user.save
      message = "You set " + @locality.name + " as an insecure locality"
      render_json({locality: localities_to_json([@locality]).first,message: message, type: "set_insecure_locality"},200)
    end
  end

  private
  def set_locality_with_no_custom_classification
    remove_locality(@current_user.custom_insecure_localities)
    remove_locality(@current_user.custom_secure_localities)
    if @current_user.save
      message = "The application will decide if " + @locality.name + " is secure or insecure"
      render_json({locality: localities_to_json([@locality]).first,message: message, type: "set_unclassified_locality"},200)
    end
  end

  private
  def locality_classification
    params[:locality_classification]
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
