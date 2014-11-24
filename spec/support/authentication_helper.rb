module AuthenticationHelpers
  def create_post(user)
      send(:post,"create",{:user =>
                              {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password }})
    end

  end
RSpec.configure do |c|
  c.include AuthenticationHelpers, type: :controller
end

