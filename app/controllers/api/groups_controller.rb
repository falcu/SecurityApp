class Api::GroupsController < ApiController
  include ApiHelper
  include Api::GroupsHelper

  before_action :set_group, except: [:create,:user_information]
  before_action  only: [:add,:remove_members,:rename] do
    authorize_creator(@group,@current_user)
  end
  before_action only: [:quit] do
    authorize_member(@group,@current_user)
  end

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
    if is_user_creator_of(@group,@current_user)
      assign_new_creator
      if @group.creator.nil?
        if @group.destroy
          respond_to do |format|
            format.json {render json: {message: 'Group deleted'}, status: 200}
          end
        else
          respond_bad_json('Unable to remove member',400)
        end
        return
      end
    elsif @group.members.include?(@current_user)
      @group.members -= [@current_user]
    end

    try_to_save_group('Unable to remove member')
  end

  def rename
    @group.name = params[:name]
    try_to_save_group('Unable to change name')
  end

  def user_information
    member_of =  Group.joins("INNER JOIN users_groups ON users_groups.group_id = groups.id").where("users_groups.user_id = ?",@current_user.id)
    creator_of = Group.where("user_id = ?", @current_user.id)
    groups = creator_of + member_of
    respond_to do |format|
      format.json { render json: {groups: groups} }
    end
  end

  private
  def group_params
    params.require(:group).permit(:name)
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
      respond_bad_json(error_message,400)
    end
  end

  private
  def set_group
    @group = Group.find(params[:id])
  end

end
