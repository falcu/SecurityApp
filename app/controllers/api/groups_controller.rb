class Api::GroupsController < ApiController
  include ApiHelper

  before_action :set_group, except: [:create]

  def create
    @group = Group.new(group_params)
    @group.creator = @current_user
    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_bad_json('Unable to create group')
    end
  end

  def add
    if is_current_user_not_creator
      respond_bad_json('You are not the creator')
      return
    end

    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member
        @group.members << new_member
      end
    end

    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_bad_json('Unable to add members')
    end
  end

  private
  def group_params
    params.require(:group).permit(:name)
  end

  private
  def set_group
    @group = Group.find(params[:id])
  end

  private
  def is_current_user_creator
     @current_user.id == @group.creator.id
  end

  private
  def is_current_user_not_creator
    not is_current_user_creator
  end

end
