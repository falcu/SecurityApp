class Api::GroupsController < ApiController
  before_action :set_user, only: [:create]

  def create
    @group = Group.new(group_params)
    @group.creator = @user
    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_to do |format|
        format.json {render json: {message: 'Unable to create group'}, status: 401}
      end
    end
  end

  private
  def group_params
    params.require(:group).permit(:name)
  end

  private
  def set_user
    @user = User.find(params[:user_id])
  end
end
