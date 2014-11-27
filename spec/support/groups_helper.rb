module GroupsHelpers
  def post_group(group,user)
    post :create , {:group => {:name => group.name },
                    :user_id => user.id,
                    :format => "json" }
  end

end
RSpec.configure do |c|
  c.include GroupsHelpers, type: :controller
end

