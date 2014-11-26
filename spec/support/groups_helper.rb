module GroupsHelpers
  def post_group(group)
    post :create , {:group => {:name => group.name },
                    :format => "json" }
  end

end
RSpec.configure do |c|
  c.include GroupsHelpers, type: :controller
end

