class Api::NotificationsController < ApiController
  include Api::LocalitiesHelper
  include Api::GroupsHelper
  include Api::UsersHelper

  before_action :set_group
  before_action do
    authorize_member(@group,@current_user)
  end
  before_action :set_notifier_builder

  def send_notification
    reg_ids = registration_ids_of_group_excluding(@group,[@current_user])
    if(reg_ids.any?)
       @builder.notifier.notify(reg_ids: reg_ids,:data => {message: @current_user.name+" has sent an alarm!", :alarm_info =>{message: params[:alarm], location: location_url(params),sender: users_to_json([@current_user]).first}, type: "notification_alarm"})
      render_json({message: "The notification was delivered"},200)
    else
      render_json({message: "The group has no members"},200)
      end
  end

  private
  def set_group
    @group = Group.find(params[:group_id])
  end

  private
  def set_notifier_builder
    @builder = NotifierBuilder.new
  end


end
