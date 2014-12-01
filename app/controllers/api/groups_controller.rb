class Api::GroupsController < ApiController
  include ApiHelper

  before_action :set_group, except: [:create]
  before_action :authorize_creator, only: [:add,:remove_members]
  before_action :authorize_member, only: [:quit]

  def create
    @group = Group.new(group_params)
    @group.creator = @current_user
    try_to_save_group('Unable to create group')
  end

  def add
    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member
        @group.members << new_member
      end
    end
    try_to_save_group('Unable to add members')
  end

  def remove_members
    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member
        @group.members -= [new_member]
      end
    end

    try_to_save_group('Unable to add members')
  end

  def quit
    if is_current_user_creator
      assign_new_creator
      if @group.creator.nil?
        if @group.destroy
          respond_to do |format|
            format.json {render json: {message: 'Group deleted'}, status: 200}
          end
        else
          respond_bad_json('Unable to remove member')
        end
        return
      end
    elsif @group.members.include?(@current_user)
      @group.members -= [@current_user]
    end

    try_to_save_group('Unable to remove member')

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

  private
  def authorize_creator
    if is_current_user_not_creator
      respond_bad_json('You are not the creator')
    end
  end

  private
  def assign_new_creator
    new_creator = @group.members.first
    @group.creator = new_creator
    if new_creator
      @group.members -= [new_creator]
    end
  end

  private
  def try_to_save_group(error_message)
    if @group.save
      respond_to do |format|
        format.json { render json: @group }
      end
    else
      respond_bad_json(error_message)
    end
  end

  private
  def authorize_member
    if is_current_user_not_creator && !@group.members.include?(@current_user)
      respond_bad_json('You are not a member of this group!')
    end
  end

end
