class Api::NotificationsController < ApiController
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_group
  before_action do
    authorize_member(@group,@current_user)
  end
  before_action :set_notifier_builder

  def send_notification
    reg_ids = registration_ids_of_group_excluding(@group,[@current_user])
    @builder.notifier.notify(reg_ids: reg_ids,:data => {message: params[:alarm], location: location_url(params)})
    render_json({message: "Done"},200)
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
