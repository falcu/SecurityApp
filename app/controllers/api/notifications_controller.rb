class Api::NotificationsController < ApiController
  include Api::LocalitiesHelper
  include Api::GroupsHelper

  before_action :set_group
  before_action do
    authorize_member(@group,@current_user)
  end

  def send_notification
    reg_ids = registration_ids(@group,@current_user)
    notifier = Notifier.new
    notifier.notify(app_name: "android_app", reg_ids: reg_ids, message: params[:alarm], location_url: location_url(params))

    respond_to do |format|
      format.json {render json: {message: 'Done'}, status: 200}
    end

  end

  private
  def set_group
    @group = Group.find(params[:group_id])
  end


end
