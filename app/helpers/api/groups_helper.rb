module Api::GroupsHelper

  include ApiHelper

  def is_user_creator_of(group,user)
    user.id == group.creator.id
  end

  def is_user_not_creator_of(group,user)
    not is_user_creator_of(group,user)
  end

  def is_user_member_of(group,user)
    group.members.include?(user)
  end

  def is_user_not_member_of(group,user)
    not is_user_member_of(group,user)
  end

  def authorize_creator(group,user)
    if is_user_not_creator_of(group,user)
      render_json('You are not the creator',401)
    end
  end

  def authorize_member(group,user)
    if is_user_not_creator_of(group,user) &&  is_user_not_member_of(group,user)
      render_json('You are not a member of this group!',401)
    end
  end

  def registration_ids(group,excluded_users)
    users = Array.new(group.members).insert(0,group.creator)
    excluded_users.each { |user| users.delete(user) }
    users.collect { |user| user.devices.map(&:registration_id) }.flatten
  end

end
