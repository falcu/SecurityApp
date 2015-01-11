module Api::UsersHelper
  def users_to_json(users)
    users.collect { |user| user.as_json(:only => [:name, :email]) }
  end
end
