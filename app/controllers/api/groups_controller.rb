class Api::GroupsController < Api::GroupsAuthorizationController
  include ApiHelper

  before_action except: [:create] do
    set_group(params[:id])
  end
  before_action :authorize_creator, only: [:add,:remove_members,:rename]
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

end
