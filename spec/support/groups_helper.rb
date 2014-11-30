module GroupsHelpers
  def post_group(group)
    post :create , {:group => {:name => group.name },
                    :format => "json" }
  end

  def put_members(group,members)
    members_emails = members.collect { |member| member.email }
    put :add, {id: group.id, :members_email => members_emails, :format => "json"}
  end

end
RSpec.configure do |c|
  c.include GroupsHelpers, type: :controller
end

