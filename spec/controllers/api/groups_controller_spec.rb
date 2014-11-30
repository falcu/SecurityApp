require 'spec_helper'

describe Api::GroupsController do
  let(:group) { FactoryGirl.build(:group) }
  let(:json) { JSON.parse(response.body) }

  before do
    FactoryGirl.create(:user)
  end

  it "Create group" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)

    expect(response.status).to eq(200)
    groupDb = Group.first
    expect(groupDb.name).to eq(group.name)
    expect(groupDb.creator.email).to eq(user.email)
    expect(groupDb.creator.name).to eq(user.name)
    expect(groupDb.creator.id).to eq(user.id)
  end

  it "Create group, json expected" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)

    expect(response.status).to eq(200)
    expect(json["name"]).to eq(group.name)
  end

  it "Create group, wrong token, access denied" do
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
    post_group(group)

    expect(Group.first).to be_nil
    expect(response.status).to eq(401)
  end

  it "Add member to group, is creator and email exists, add correctly" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)

    expect(Group.first.members.count).to be(0)
    new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
    members = [new_member]
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    put_members(Group.first,members)

    expect(response.status).to eq(200)
    expect(Group.first.members.count).to eq(1)
    expect(Group.first.members.first.email).to eq(new_member.email)
  end

  it "Add member to group, if not creator, access denied" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)

    new_member = FactoryGirl.create(:user, :name => "new_member", :email => "new_member@someemail.com", :password => "123456")
    members = [new_member]
    other_user = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(other_user.token)
    put_members(Group.first,members)

    expect(response.status).to eq(401)
    expect(Group.first.members.count).to eq(0)
  end

  it "Add 2 members to group" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)

    expect(Group.first.members.count).to eq(0)
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    members = [new_member1,new_member2]
    put_members(Group.first,members)

    expect(response.status).to eq(200)
    expect(Group.first.members.count).to eq(2)
  end

  it "Delete 1 member, is creator, succeded" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(1)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    members = [new_member1]
    delete_members(saved_group,members)
    saved_group.reload

    expect(response.status).to eq(200)
    expect(saved_group.members.count).to eq(0)
  end

  it "Delete 1 member, is not creator, access denied" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(1)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
    members = [new_member1]
    delete_members(saved_group,members)
    saved_group.reload

    expect(response.status).to eq(401)
    expect(saved_group.members.count).to eq(1)
  end

  it "Delete 2 members" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.members << new_member2
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(2)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    members = [new_member1,new_member2]
    delete_members(saved_group,members)
    saved_group.reload

    expect(response.status).to eq(200)
    expect(saved_group.members.count).to eq(0)
  end

  it "Member quits group" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.members << new_member2
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(2)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(new_member1.token)
    put :quit, {id: saved_group.id, :format => "json"}
    saved_group.reload

    expect(response.status).to eq(200)
    expect(saved_group.members.count).to eq(1)
  end

  it "Not a member tries to quit group" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(1)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(new_member2.token)
    put :quit, {id: saved_group.id, :format => "json"}
    saved_group.reload

    expect(response.status).to eq(401)
    expect(saved_group.members.count).to eq(1)
  end

  it "Creator quits group, members available ,new creator is assigned" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    saved_group = Group.first
    new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
    new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
    saved_group.members << new_member1
    saved_group.members << new_member2
    saved_group.save
    saved_group.reload
    expect(saved_group.members.count).to eq(2)
    creator_candidates = [new_member1, new_member2]

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    put :quit, {id: saved_group.id, :format => "json"}
    saved_group.reload

    expect(response.status).to eq(200)
    expect(saved_group.members.count).to eq(1)
    expect(creator_candidates.include?(saved_group.creator)).to be_true
  end

  it "Creator quits group, no members, group is deleted" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group)
    id = Group.first.id

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    put :quit, {id: id, :format => "json"}

    expect(response.status).to eq(200)
    expect {Group.find(id)}.to raise_exception
  end

end
