module ApiHelpers
  def create_app_for_push_notification
    app = Rpush::Gcm::App.new
    app.name = "android_app"
    app.auth_key = "123"
    app.connections = 1
    app.save!
  end

  def create_group_with_users
    creator = User.new(name: "creator", email: "creator@email.com", password: "123456", password_confirmation: "123456")
    creator.devices << Device.new(registration_id: "creator_123")
    creator.save

    user1 = User.new(name: "user1", email: "user1@email.com", password: "123456", password_confirmation: "123456")
    user1.devices << Device.new(registration_id: "user1_123")
    user1.save

    user2 = User.new(name: "user2", email: "user2@email.com", password: "123456", password_confirmation: "123456")
    user2.devices << Device.new(registration_id: "user2_123")
    user2.save

    group = Group.new(name: "group1")
    group.creator = creator
    group.members << user1
    group.members << user2
    group.save
  end

end
RSpec.configure do |c|
  c.include ApiHelpers, type: :controller
end

