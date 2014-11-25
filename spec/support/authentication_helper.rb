module AuthenticationHelpers
  def post_user(user)
     post :create , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                    :format => "json"}
    end

  end
RSpec.configure do |c|
  c.include AuthenticationHelpers, type: :controller
end

