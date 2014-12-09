class Api::NotificationsController < Api::GroupsAuthorizationController
  include Api::LocalitiesHelper

  before_action do
    set_group(params[:group_id])
  end
  before_action :authorize_member

  def notify
    reg_ids = registration_ids
    notification = Rpush::Gcm::Notification.new
    #notification.app = "android_app"
    notification.registration_ids = ["token", reg_ids]
    notification.data = { message: params[:alarm], location: location_url(params) }
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


end
