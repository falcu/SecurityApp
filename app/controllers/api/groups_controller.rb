class Api::GroupsController < ApiController
  include ApiHelper

  before_action :set_group, except: [:create]
  before_action :check_creator, only: [:add,:remove_members]

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

  def remove_members

    (params[:members_email]).each do |email|
      new_member = User.find_by_email(email)
      if new_member
        @group.members -= [new_member]
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
      if @group.save
        respond_to do |format|
          format.json { render json: @group }
        end
      else
        respond_bad_json('Unable to remove member')
      end
    elsif @group.members.include?(@current_user)
      @group.members -= [@current_user]
      if @group.save
        respond_to do |format|
          format.json { render json: @group }
        end
      else
        respond_bad_json('Unable to remove member')
      end
    else
      respond_bad_json('You are not a member of this group!')
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

  private
  def check_creator
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

end
