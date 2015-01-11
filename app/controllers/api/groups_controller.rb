class Api::GroupsController < ApiController
  include ApiHelper
  include Api::GroupsHelper
  include Api::UsersHelper

  before_action :set_group, except: [:create, :user_information]
  before_action only: [:add, :remove_members, :rename] do
    authorize_creator(@group, @current_user)
  end
  before_action only: [:quit] do
    authorize_member(@group, @current_user)
  end
  before_action :set_notifier_builder
  before_action :validate_creator_not_adding_himself, only: [:add, :remove_members]

  def create
    @group = Group.new(group_params)
    @group.creator = @current_user
    try_to_save_group({group: @group}, {error: "Unable to create group"})
  end

  def add
    user_exists = true
    new_members = []
    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member
        new_members << new_member
      else
        user_exists = false
      end
    end
    if user_exists
      new_members.each { |new_member| @group.members<<new_member }
      creator_json = creator_to_json
      members = users_to_json(@group.members)
      try_to_save_group({:group_info => {group: @group, members: members}}, {error: "Unable to add members"})
      reg_ids_old_members = registration_ids_of(@group.members - new_members)
      @builder.notifier.notify(reg_ids: reg_ids_old_members, :data => {message: "New member/s added", :group_info => {group: @group, members: members, creator: creator_json}, type: "member_added"})
      reg_ids_new_members = registration_ids_of(new_members)
      @builder.notifier.notify(reg_ids: reg_ids_new_members, :data => {message: "You were added to a group", :group_info => {group: @group, members: members, creator: creator_json}, type: "added"})
    else
      render_json({error: "At least one user does not exist"},400)
    end
  end

  def remove_members
    is_member = true
    members_to_delete = []
    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member && @group.members.include?(new_member)
        members_to_delete << new_member
      else
        is_member = false
      end
    end
    if is_member
      actual_members = users_to_json(@group.members - members_to_delete)
      creator_json = creator_to_json
      members_to_delete.each { |member| @group.members -= [member] }
      try_to_save_group({:group_info => {group: @group, members: actual_members}}, {error: "Unable to remove members"})
      reg_ids_members = registration_ids_of_group_excluding(@group,[@group.creator])
      @builder.notifier.notify(reg_ids: reg_ids_members, :data => {message: "Member deleted", :group_info => {group: @group, members: actual_members, creator: creator_json}, type: "member_deleted"})
      reg_ids_deleted_members = registration_ids_of(members_to_delete)
      @builder.notifier.notify(reg_ids: reg_ids_deleted_members, :data => {message: "You were deleted", :group_info => {group: @group}, type: "deleted"})
    else
      render_json({error: "At least one member doest not exist or is not a member of the group"}, 400)
    end
  end

  def quit
    if is_user_creator_of(@group, @current_user)
      assign_new_creator
      if @group.creator.nil?
        if @group.destroy
          render_json({message: "Group deleted"}, 200)
        else
          render_json({error: "Unable to remove member"}, 400)
        end
        return
      end
    elsif @group.members.include?(@current_user)
      @group.members -= [@current_user]
    end

    if try_to_save_group({group: @group}, {error: "Unable to remove member"})
      reg_ids = registration_ids_of_group_excluding(@group, [])
      actual_members = users_to_json(@group.members)
      creator_json = creator_to_json
      @builder.notifier.notify(reg_ids: reg_ids, :data => {message: "Member has quitted", :group_info => {group: @group, members: actual_members, creator: creator_json}, type: "member_quitted"})
    end
  end

  def rename
    @group.name = params[:name]
    if try_to_save_group({message: "Group name changed", :group_info => {group: @group}, type: "name_changed"}, {error: "Unable to change name"})
      reg_ids = registration_ids_of_group_excluding(@group, [@current_user])
      @builder.notifier.notify(reg_ids: reg_ids, :data => {message: "Group name changed", :group_info => {group: @group}, type: "name_changed"})
    end
  end

  def user_information
    member_of = Group.joins("INNER JOIN users_groups ON users_groups.group_id = groups.id").where("users_groups.user_id = ?", @current_user.id)
    creator_of = Group.where("user_id = ?", @current_user.id)
    groups = creator_of + member_of
    group_info = groups.collect { |group| {group: group, members: users_to_json(group.members), creator: users_to_json([group.creator]).first} }
    render_json({group_info: group_info}, 200)
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
  def try_to_save_group(json_args, error_message)
    if @group.save
      render_json(json_args, 200)
      true
    else
      render_json(error_message, 400)
      false
    end
  end

  private
  def set_group
    @group = Group.find(params[:id])
  end

  private
  def set_notifier_builder
    @builder = NotifierBuilder.new
  end

  private
  def validate_creator_not_adding_himself
    if params[:members_email].include?(@current_user.email)
      render_json({:error => "You are the creator, you cannot add or remove yourself!"},400)
    end
  end

  private
  def creator_to_json
    @group.creator.as_json(:only => [:name,:email])
  end

end
