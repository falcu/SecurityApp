module GroupsHelpers
  def create_group(group)
    post :create , {:group => {:name => group.name },
                    :format => "json" }
  end

  def add_members(group,members)
    members_emails = members.collect { |member| member.email }
    put :add, {id: group.id, :members_email => members_emails, :format => "json"}
  end

  def delete_members(group,members)
    members_emails = members.collect { |member| member.email }
    delete :remove_members, {id: group.id, :members_email => members_emails, :format => "json"}
  end

  def quit_group(group)
    put :quit, {id: group.id, :format => "json"}
  end

  def rename_group(group,name)
    put :rename, {id: group.id,:name => name ,:format => "json"}
  end

  def get_group_information
    get :group_information, {:format => "json"}
  end

end
RSpec.configure do |c|
  c.include GroupsHelpers, type: :controller
end

