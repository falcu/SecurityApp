class Api::GroupsAuthorizationController < ApiController

  def set_group(id)
    @group = Group.find(id)
  end

  def is_current_user_creator
    @current_user.id == @group.creator.id
  end

  def is_current_user_not_creator
    not is_current_user_creator
  end

  def is_current_user_member
    @group.members.include?(@current_user)
  end

  def is_current_not_member
    not is_current_user_member
  end

  def authorize_creator
    if is_current_user_not_creator
      respond_bad_json('You are not the creator',401)
    end
  end

  def authorize_member
    if is_current_user_not_creator && is_current_not_member
      respond_bad_json('You are not a member of this group!',401)
    end
  end

end