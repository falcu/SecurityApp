require 'spec_helper'

describe Api::GroupsController do
  let(:group) { FactoryGirl.build(:group) }
  let(:json) { JSON.parse(response.body) }

  before do
    FactoryGirl.create(:user)
  end

  context "Create a group" do

    it "Create group with correct token" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      expect(response.status).to eq(200)
      groupDb = Group.first
      expect(groupDb.name).to eq(group.name)
      expect(groupDb.creator.email).to eq(user.email)
      expect(groupDb.creator.name).to eq(user.name)
      expect(groupDb.creator.id).to eq(user.id)
    end

    it "Create group with correct token, json expected" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      expect(response.status).to eq(200)
      expect(json["group"]["name"]).to eq(group.name)
    end

    it "Create group, wrong token, access denied" do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      create_group(group)

      expect(Group.first).to be_nil
      expect(response.status).to eq(401)
    end

  end

  context "Add a member to group" do

    it "Is creator and email exists, add correctly" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      expect(Group.first.members.count).to be(0)
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      members = [new_member]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_members(Group.first, members)

      expect(response.status).to eq(200)
      expect(Group.first.members.count).to eq(1)
      expect(Group.first.members.first.email).to eq(new_member.email)
    end

    it "Add member to group, if not creator, access denied" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      new_member = FactoryGirl.create(:user, :name => "new_member", :email => "new_member@someemail.com", :password => "123456")
      members = [new_member]
      other_user = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(other_user.token)
      add_members(Group.first, members)

      expect(response.status).to eq(401)
      expect(Group.first.members.count).to eq(0)
    end

    it "Add 2 members to group" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      expect(Group.first.members.count).to eq(0)
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1, new_member2]
      add_members(Group.first, members)

      expect(response.status).to eq(200)
      expect(Group.first.members.count).to eq(2)
    end

    it "Is creator and email exists, json with group info returned" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      expect(Group.first.members.count).to be(0)
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      members = [new_member]
      saved_group = Group.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_members(saved_group, members)
      saved_group.reload
      new_member.reload

      expect(response.status).to eq(200)
      expect(json["group_info"]["group"]["name"]).to eq(saved_group.name)
      expect(json["group_info"]["members"]).to eq([new_member , user].collect { |user| user.as_json(:only=>[:name,:email]) })
    end

    it "Add member to group, all other members are notified" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      double = double("Notifier")
      members_args = (Array.new(saved_group.members) << new_member << creator).collect { |user| user.as_json(:only => [:name,:email]) }
      expected_args = {reg_ids: "user1_123,user2_123,new_user_123", :data => {message: "New member added", :group_info=>{group: saved_group, members: members_args}, type: "member_added" }}
      expect(double).to receive(:notify).with(expected_args)
      expect(double).to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      members = [new_member]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_members(saved_group, members)

    end

    it "Not creator, access denied and members are not notified" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      double = double("Notifier")
      members_args = (Array.new(saved_group.members) << new_member << creator).collect { |user| user.as_json(:only => [:name,:email]) }
      expected_args = {reg_ids: "user1_123,user2_123,new_user_123", :data => {message: "New member added", :group_info=>{group: saved_group, members: members_args}, type: "member_added" }}
      expect(double).not_to receive(:notify).with(expected_args)
      expect(double).not_to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      members = [new_member]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("fake_token")
      add_members(saved_group, members)
    end


  end

  context "Delete member" do

    it "Delete 1 member, is creator, succeded" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      saved_group.reload
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(0)
    end

    it "Delete 1 member, is not creator, access denied" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      saved_group.reload
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      members = [new_member1]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(401)
      expect(saved_group.members.count).to eq(1)
    end

    it "Delete 2 members" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.members << new_member2
      saved_group.save
      saved_group.reload
      expect(saved_group.members.count).to eq(2)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1, new_member2]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(0)
    end

  end

  context "Member quits group" do

    it "Member quits group with correct credentials, member removed" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.members << new_member2
      saved_group.save
      saved_group.reload
      expect(saved_group.members.count).to eq(2)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(new_member1.token)
      quit_group(saved_group)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(1)
    end

    it "Not a member tries to quit group, access denied" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      saved_group.reload
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(new_member2.token)
      quit_group(saved_group)
      saved_group.reload

      expect(response.status).to eq(401)
      expect(saved_group.members.count).to eq(1)
    end

    it "Creator quits group, members available ,new creator is assigned" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
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
      quit_group(saved_group)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(1)
      expect(creator_candidates.include?(saved_group.creator)).to be_true
    end

    it "Creator quits group, no other members, group is deleted" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      quit_group(saved_group)

      expect(response.status).to eq(200)
      expect { Group.find(saved_group.id) }.to raise_exception
    end

  end

  context "Creator renames group" do

    it "Creator renames group , name changed" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      expected_name = "new name"
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(saved_group, expected_name)

      expect(response.status).to eq(200)
      expect(Group.first.name).to eq(expected_name)
    end

    it "Creator renames group , json with group info returned" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      expected_name = "new name"
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(saved_group, expected_name)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(json["group"]["name"]).to eq(saved_group.name)
    end

    it "Fake user tries to change name, access denied and name unchanged" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      expected_name = "new name"

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      rename_group(saved_group, expected_name)

      expect(response.status).to eq(401)
      expect(Group.first.name).to eq(saved_group.name)
    end

    it "Creator renames group , all of the other users are notified" do
      create_group_with_users
      user = User.find_by_name("creator")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      group = Group.find_by_name("group1")
      expected_name = "new name"
      double = double("Notifier")
      expected_args = {reg_ids: "user1_123,user2_123", :data => {message: "Group name changed", group: group, type: "name_changed" }}
      expect(double).to receive(:notify).with(expected_args)
      expect(double).to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(group, expected_name)
    end

  end

  context "Get user information" do

    it "A user that creates 1 groups, gets his groups information" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get :user_information, {:format => "json"}

      expect(response.status).to eq(200)
      expect(json["groups"].count).to eq(1)
      expect(json["groups"][0]["name"]).to eq(group.name)
    end

    it "A user that creates 2 groups, gets his groups information" do
      user = User.first
      group1 = FactoryGirl.build(:group, :name => "group1")
      group2 = FactoryGirl.build(:group, :name => "group2")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group1)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group2)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get :user_information, {:format => "json"}

      expect(response.status).to eq(200)
      expect(json["groups"].count).to eq(2)
      expect(json["groups"][0]["name"]).to eq(group1.name)
      expect(json["groups"][1]["name"]).to eq(group2.name)
    end

    it "A user that creates 1 groups and is member of other group, gets his groups information" do
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)
      user = User.first
      other_user = FactoryGirl.create(:user, name: "other_user", email: "other_user@email.com", password: "123")
      group1 = FactoryGirl.build(:group, :name => "group1")
      group2 = FactoryGirl.build(:group, :name => "group2")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group1)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(other_user.token)
      create_group(group2)
      members = [user]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(other_user.token)
      group2 = Group.find_by_name("group2")
      add_members(group2, members)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get :user_information, {:format => "json"}

      expect(response.status).to eq(200)
      expect(json["groups"].count).to eq(2)
      expect(json["groups"][0]["name"]).to eq(group1.name)
      expect(json["groups"][1]["name"]).to eq(group2.name)
    end

  end

end
