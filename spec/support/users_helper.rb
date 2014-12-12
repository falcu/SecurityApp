module UserHelpers
  def create_user(user)
    post :create , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                    :format => "json"}
  end

end
RSpec.configure do |c|
  c.include UserHelpers, type: :controller
end

