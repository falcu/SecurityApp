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
      expect(json["group_info"]["group"]["name"]).to eq(group.name)
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
      expect(json["group_info"]["members"]).to eq([new_member].collect { |user| user.as_json(:only=>[:name,:email]) })
    end

    it "Add first member to new group, only new member receives push notification as there are no older members" do
      creator = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      create_group(group)
      new_member = FactoryGirl.build(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "123456")
      new_member.save
      members = [new_member]
      saved_group = Group.first
      members_args = (Array.new(saved_group.members)<<new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["123456"], :data => {message: "You were added to a group", :group_info=>{group: saved_group, members: members_args, creator: creator_json}, type: "added" }}
      double = double("Notifier")
      expect(double).to receive(:app_name=).once
      expect(double).to receive(:notify).with(expected_args).once
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_members(saved_group, members)
      create_group(group)



    end

    it "Add member to group, all other members are notified" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      double = double("Notifier")
      members_args = (Array.new(saved_group.members) << new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_arg = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["user1_123","user2_123"], :data => {message: "New member/s added", :group_info=>{group: saved_group, members: members_args, creator: creator_arg}, type: "member_added" }}
      expect(double).to receive(:app_name=).twice
      i = 1
      expect(double).to receive(:notify).twice do |arg|
        if i == 1
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
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

    it "Attempt to add non existent user" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      expect(double).not_to receive(:app_name=)
      expect(double).not_to receive(:notify)
      Notifier.stub(:new).and_return(double)

      new_member1 = FactoryGirl.build(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      members = [new_member1]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_members(Group.first, members)

      expect(response.status).to eq(400)
    end

    it "Attempt to add 2 users, 1 does not exist, none is added" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      expect(double).not_to receive(:app_name=)
      expect(double).not_to receive(:notify)
      Notifier.stub(:new).and_return(double)

      group = Group.first
      expect(group.members.count).to eq(0)
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.build(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      members = [new_member1, new_member2]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_members(Group.first, members)

      group.reload
      expect(response.status).to eq(400)
      expect(group.members.count).to eq(0)
    end

    it "Add 1 member to group with 2 members, push notification is sent to new member" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.build(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      members_args = (Array.new(saved_group.members)<<new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["new_user_123"], :data => {message: "You were added to a group", :group_info=>{group: saved_group, members: members_args, creator: creator_json}, type: "added" }}
      double = double("Notifier")
      expect(double).to receive(:app_name=).twice
      i = 1
      expect(double).to receive(:notify).twice do |arg|
        if i == 2
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_members(Group.first, [new_member])
    end

  end

  context "Add single member to group" do

    it "Is creator and email exists, add correctly" do
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
      add_single_group_members(Group.first, members)

      expect(response.status).to eq(200)
      expect(Group.first.members.count).to eq(2)
    end

    it "if not creator, access denied" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      new_member = FactoryGirl.create(:user, :name => "new_member", :email => "new_member@someemail.com", :password => "123456")
      members = [new_member]
      other_user = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(other_user.token)
      add_single_group_members(Group.first, members)

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
      add_single_group_members(Group.first, members)

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
      add_single_group_members(saved_group, members)
      saved_group.reload
      new_member.reload

      expect(response.status).to eq(200)
      expect(json["group_info"]["group"]["name"]).to eq(saved_group.name)
      expect(json["group_info"]["members"]).to eq([new_member].collect { |user| user.as_json(:only=>[:name,:email]) })
    end

    it "Add first member to new group, only new member receives push notification as there are no older members" do
      creator = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      create_group(group)
      new_member = FactoryGirl.build(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "123456")
      new_member.save
      members = [new_member]
      saved_group = Group.first
      members_args = (Array.new(saved_group.members)<<new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["123456"], :data => {message: "You were added to a group", :group_info=>{group: saved_group, members: members_args, creator: creator_json}, type: "added" }}
      double = double("Notifier")
      expect(double).to receive(:app_name=).once
      expect(double).to receive(:notify).with(expected_args).once
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_single_group_members(saved_group, members)

    end

    it "Add member to group, all other members are notified" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.create(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      double = double("Notifier")
      members_args = (Array.new(saved_group.members) << new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_arg = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["user1_123","user2_123"], :data => {message: "New member/s added", :group_info=>{group: saved_group, members: members_args, creator: creator_arg}, type: "member_added" }}
      expect(double).to receive(:app_name=).twice
      i = 1
      expect(double).to receive(:notify).twice do |arg|
        if i == 1
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
      Notifier.stub(:new).and_return(double)

      members = [new_member]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_single_group_members(saved_group, members)

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
      add_single_group_members(saved_group, members)
    end

    it "Attempt to add non existent user" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      expect(double).not_to receive(:app_name=)
      expect(double).not_to receive(:notify)
      Notifier.stub(:new).and_return(double)

      new_member1 = FactoryGirl.build(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      members = [new_member1]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_single_group_members(Group.first, members)

      expect(response.status).to eq(400)
    end

    it "Attempt to add 2 users, 1 does not exist, none is added" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      double = double("Notifier")
      expect(double).not_to receive(:app_name=)
      expect(double).not_to receive(:notify)
      Notifier.stub(:new).and_return(double)

      group = Group.first
      expect(group.members.count).to eq(0)
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member2 = FactoryGirl.build(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      members = [new_member1, new_member2]
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      add_single_group_members(Group.first, members)

      group.reload
      expect(response.status).to eq(400)
      expect(group.members.count).to eq(0)
    end

    it "Add 1 member to group with 2 members, push notification is sent to new member" do
      create_group_with_users
      creator = User.find_by_name("creator")
      new_member = FactoryGirl.build(:user, :name => "new_user", :email => "new_user@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      new_member.save
      saved_group = Group.first
      members_args = (Array.new(saved_group.members)<<new_member).collect { |user| user.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["new_user_123"], :data => {message: "You were added to a group", :group_info=>{group: saved_group, members: members_args, creator: creator_json}, type: "added" }}
      double = double("Notifier")
      expect(double).to receive(:app_name=).twice
      i = 1
      expect(double).to receive(:notify).twice do |arg|
        if i == 2
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      add_single_group_members(Group.first, [new_member])
    end

    it "Add 1 user to a group, then try to add same user to another group, error obtained" do
      create_group_with_users
      user = User.first
      member_to_add = User.find_by_name("user2")
      extra_group = FactoryGirl.build(:group,:name => "extra_group")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_extra_group = Group.find_by_name(group.name)

      add_single_group_members(saved_extra_group,[member_to_add])

      expect(json["error"]).to eq("member already belongs to a group")

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
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)
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
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)
      expect(saved_group.members.count).to eq(2)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1, new_member2]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(0)
    end

    it "Delete the only member in the group, json with group info is returned" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      saved_group.reload
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(0)
      expect(json["group_info"]["group"]["name"]).to eq(saved_group.name)
      expect(json["group_info"]["members"]).to eq([])
    end

    it "Delete 1 of 2 members, json with group info is returned" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      member_to_delete = User.find_by_email("user1@email.com")
      saved_group = Group.first
      double = double("Notifier")
      allow(double).to receive(:app_name=)
      allow(double).to receive(:notify)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      members = [member_to_delete]
      delete_members(saved_group, members)
      saved_group.reload
      expected_members = saved_group.members.collect { |user| user.as_json(:only => [:name, :email]) }

      expect(response.status).to eq(200)
      expect(saved_group.members.count).to eq(1)
      expect(json["group_info"]["group"]["name"]).to eq(saved_group.name)
      expect(json["group_info"]["members"]).to eq(expected_members)
    end

    it "Attempt to delete non-member, json with error returned, nothing changed" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      saved_group.reload
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member2]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(400)
      expect(saved_group.members.count).to eq(1)
    end

    it "Attempt to delete 2 members, 1 is not a member, json with error returned, nothing changed" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member1 = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      saved_group.members << new_member1
      saved_group.save
      new_member2 = FactoryGirl.create(:user, :name => "new_member2", :email => "new_member2@someemail.com", :password => "123456")
      saved_group.reload
      expect(saved_group.members.count).to eq(1)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      members = [new_member1,new_member2]
      delete_members(saved_group, members)
      saved_group.reload

      expect(response.status).to eq(400)
      expect(saved_group.members.count).to eq(1)
    end

    it "Delete 1 member, notification send to all other members with new group info" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      member_to_delete = User.find_by_email("user1@email.com")
      saved_group = Group.first
      other_members = Array.new(saved_group.members)
      other_members-= [member_to_delete]

      double = double("Notifier")
      members_args = other_members.collect { |user| user.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["user2_123"], :data => {message: "Member deleted", :group_info=>{group: saved_group, members: members_args, creator: creator_json}, type: "member_deleted" }}
      i = 1
      expect(double).to receive(:notify).twice do |arg|
        if i ==1
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
      expect(double).to receive(:app_name=).twice
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      members = [member_to_delete]
      delete_members(saved_group, members)

    end

    it "Delete 1 member of 2, separate notification sent to deleted member" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      member_to_delete = User.find_by_email("user1@email.com")
      saved_group = Group.first
      expected_args = {reg_ids: ["user1_123"], :data => {message: "You were deleted", :group_info=>{group: saved_group}, type: "deleted" }}

      notifier = double("notifier")
      expect(notifier).to receive(:app_name=).twice
      i = 1
      expect(notifier).to receive(:notify).twice do |arg|
        if i == 2
          expect(arg).to eq(expected_args)
        end
        i+=1
      end
      Notifier.stub(:new).and_return(notifier)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      members = [member_to_delete]
      delete_members(saved_group, members)
    end

    it "Delete the only member of the group, only one push notificaiton is sent separately to deleted member" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      saved_group = Group.first
      new_member = FactoryGirl.create(:user, :name => "new_member1", :email => "new_member1@someemail.com", :password => "123456")
      new_member.devices << Device.new(registration_id: "new_user_123")
      saved_group.members << new_member
      saved_group.save
      expected_args = {reg_ids: ["new_user_123"], :data => {message: "You were deleted", :group_info=>{group: saved_group}, type: "deleted" }}
      double = double("Notifier")
      expect(double).to receive(:app_name=).once
      expect(double).to receive(:notify).with(expected_args).once
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      delete_members(saved_group, [new_member])


    end

    it "Creator tries to delete himself, json with error returned, nothing is changed" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      saved_group = Group.first

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      members = [creator]
      delete_members(saved_group, members)

      expect(response.status).to eq(400)
      expect(saved_group.members.count).to eq(2)
      expect(json["error"]).to eq("You are the creator, you cannot add or remove yourself!")
    end

  end

  context "Member quits group" do

    it "Member quits group with correct credentials, member removed" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      notifier = double("notifier")
      Notifier.stub(:new).and_return(notifier)
      allow(notifier).to receive(:app_name=)
      allow(notifier).to receive(:notify)
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
      notifier = double("notifier")
      Notifier.stub(:new).and_return(notifier)
      allow(notifier).to receive(:app_name=)
      allow(notifier).to receive(:notify)
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

    it "Member quits group, all other members are notified with new group information" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      member_to_quit = User.find_by_email("user1@email.com")
      saved_group = Group.first
      members_json = (saved_group.members - [member_to_quit]).collect { |user| user.as_json(:only => [:name, :email]) }
      creator_json = creator.as_json(:only => [:name, :email])
      expected_args = {reg_ids: ["creator_123","user2_123"], :data => {message: "Member has quitted", :group_info=>{group: saved_group, members: members_json, creator: creator_json}, type: "member_quitted" }}
      notifier = double("notifier")
      Notifier.stub(:new).and_return(notifier)

      expect(notifier).to receive(:app_name=)
      expect(notifier).to receive(:notify).with(expected_args)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(member_to_quit.token)
      quit_group(saved_group)

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
      expect(json["group_info"]["group"]["name"]).to eq(saved_group.name)
      expect(json["type"]).to eq("name_changed")
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
      creator = User.find_by_name("creator")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      group = Group.find_by_name("group1")
      expected_name = "new name"
      double = double("Notifier")
      members_json = group.members.collect { |m| m.as_json(:only => [:name,:email]) }
      creator_json = creator.as_json(:only => [:name,:email])
      expected_args = {reg_ids: ["user1_123","user2_123"], :data => {message: "Group name changed", :group_info => {group: group, members: members_json, creator: creator_json}, type: "name_changed" }}
      expect(double).to receive(:notify).with(expected_args)
      expect(double).to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      rename_group(group, expected_name)
    end

    it "Creator renames group, group has no members, no push notification is sent" do
      load Rails.root + "db/seeds.rb"
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)
      group = Group.first
      double = double("Notifier")
      expect(double).not_to receive(:notify)
      expect(double).not_to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(group,"new_name")
    end

    it "Creator tries to rename group with same name, no push notification is sent" do
      create_group_with_users
      user = User.find_by_name("creator")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      group = Group.find_by_name("group1")
      double = double("Notifier")
      expect(double).not_to receive(:notify)
      expect(double).not_to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(group,group.name)
    end

    it "Creator tries to rename group with same name, error get" do
      create_group_with_users
      user = User.find_by_name("creator")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      group = Group.find_by_name("group1")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      rename_group(group,group.name)

      expect(json["error"]).not_to be_nil
    end

  end

  context "User gets groups info" do

    it "A user that creates 1 groups, gets his groups information" do
      user = User.first
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get_group_information

      expect(response.status).to eq(200)
      expect(json["group_info"].count).to eq(1)
      expect(json["group_info"][0]["group"]["name"]).to eq(group.name)
      expect(json["group_info"][0]["members"]).to eq([])
      expect(json["group_info"][0]["creator"]).to eq(user.as_json(:only => [:name,:email]))
    end

    it "A user that creates 2 groups, gets his groups information" do
      user = User.first
      expected_creator_json = user.as_json(:only => [:name,:email])
      group1 = FactoryGirl.build(:group, :name => "group1")
      group2 = FactoryGirl.build(:group, :name => "group2")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group1)
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      create_group(group2)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get_group_information

      expect(response.status).to eq(200)
      expect(json["group_info"].count).to eq(2)
      expect(json["group_info"][0]["group"]["name"]).to eq(group1.name)
      expect(json["group_info"][0]["members"]).to eq([])
      expect(json["group_info"][0]["creator"]).to eq(expected_creator_json)
      expect(json["group_info"][1]["group"]["name"]).to eq(group2.name)
      expect(json["group_info"][1]["members"]).to eq([])
      expect(json["group_info"][1]["creator"]).to eq(expected_creator_json)
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
      group1 = Group.find_by_name("group1")
      group2 = Group.find_by_name("group2")
      group1_creator_json = group1.creator.as_json(:only => [:name,:email])
      group1_members_json = []
      group2_creator_json = group2.creator.as_json(:only => [:name,:email])
      group2_members_json = group2.members.collect { |member| member.as_json(:only => [:name,:email]) }


      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get_group_information

      expect(response.status).to eq(200)
      expect(json["group_info"].count).to eq(2)
      expect(json["group_info"][0]["group"]["name"]).to eq(group1.name)
      expect(json["group_info"][0]["members"]).to eq(group1_members_json)
      expect(json["group_info"][0]["creator"]).to eq(group1_creator_json)
      expect(json["group_info"][1]["group"]["name"]).to eq(group2.name)
      expect(json["group_info"][1]["members"]).to eq(group2_members_json)
      expect(json["group_info"][1]["creator"]).to eq(group2_creator_json)
    end

    it "Creator of group with 2 members, requests information" do
      create_group_with_users
      creator = User.find_by_email("creator@email.com")
      group = Group.first
      group_members_json = group.members.collect { |member| member.as_json(:only => [:name,:email]) }
      group_creator_json = group.creator.as_json(:only => [:name,:email])

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
      get_group_information

      expect(response.status).to eq(200)
      expect(json["group_info"].count).to eq(1)
      expect(json["group_info"][0]["group"]["name"]).to eq(group.name)
      expect(json["group_info"][0]["members"]).to eq(group_members_json)
      expect(json["group_info"][0]["creator"]).to eq(group_creator_json)
    end

    it "Member of group with 2 members, requests information" do
      create_group_with_users
      member = User.find_by_email("user1@email.com")
      group = Group.first
      group_members_json = group.members.collect { |member| member.as_json(:only => [:name,:email]) }
      group_creator_json = group.creator.as_json(:only => [:name,:email])

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(member.token)
      get_group_information

      expect(response.status).to eq(200)
      expect(json["group_info"].count).to eq(1)
      expect(json["group_info"][0]["group"]["name"]).to eq(group.name)
      expect(json["group_info"][0]["members"]).to eq(group_members_json)
      expect(json["group_info"][0]["creator"]).to eq(group_creator_json)
    end

  end

end
