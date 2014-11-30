class Api::GroupsController < ApiController
  before_action :set_user, only: [:create]
  before_action :set_group, except: [:create]

  def create
    @group = Group.new(group_params)
    @group.creator = @user
    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_bad_json('Unable to create group')
    end
  end

  def add
    new_member = User.find_by_email(params[:member_email])
    message = 'Unable to add member'
    if new_member
      @group.members << new_member
      if @group.save
        respond_to do |format|
          format.json { render json: @group }
        end
      else
        respond_bad_json(message)
      end
    else
      respond_bad_json(message)
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

  private
  def set_group
    @group = Group.find(params[:id])
  end

end
