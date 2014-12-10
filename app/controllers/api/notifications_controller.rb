class Api::NotificationsController < ApiController
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_group
  before_action do
    authorize_member(@group,@current_user)
  end

  def send_notification
    reg_ids = registration_ids(@group,@current_user)
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
  def set_group
    @group = Group.find(params[:group_id])
  end


end
