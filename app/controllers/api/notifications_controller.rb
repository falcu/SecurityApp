class Api::NotificationsController < ApiController
  include Api::LocalitiesHelper

  before_action :set_group
  before_action :authorize_member

  def notify
    reg_ids = registration_ids
    notification = Rpush::Gcm::Notification.new
    #notification.app = "android_app"
    notification.registration_ids = ["token", reg_ids]
    notification.data = { message: params[:alarm], location: location_url(params[:latitude],params[:longitude]) }
    notification.save!

    respond_to do |format|
      format.json {render json: {message: 'Done'}, status: 200}
    end

  end

  private
  def registration_ids
    if is_current_user_creator
      reg_ids = @group.members.collect{|user| user.devices.map(&:registration_id).join(",")}.join(",")
    elsif is_current_user_member
      members = Array.new(@group.members)
      members.insert(0,@group.creator)
      reg_ids = members.select{|member| member.id!=@current_user.id}.collect{|user| user.devices.map(&:registration_id).join(",")}.join(",")
    end
  end

  private
  def is_current_user_creator
    @current_user.id == @group.creator.id
  end

  private
  def is_current_user_member
    @group.members.include?(@current_user)
  end

  private
  def set_group
    @group = Group.find(params[:group_id])
  end

  private
  def authorize_member
    if !is_current_user_creator && !is_current_user_member
      respond_bad_json('You are not a member of this group!',401)
    end
  end


end
