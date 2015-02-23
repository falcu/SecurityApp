require 'spec_helper'


describe Api::NotificationsController do
  let(:json) { JSON.parse(response.body) }

  it "Creator of a group sends alarm, the other members are notified with custom message and the current location" do
    load Rails.root + "db/seeds.rb"
    create_group_with_users
    group = Group.find_by_name("group1")
    creator = User.find_by_email("creator@email.com")
    expected_args = {reg_ids: ["user1_123","user2_123"],:data=>{message: "creator has sent an alarm!", :alarm_info=> {message: "I'm in danger", location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z" ,sender: creator.as_json(:only => [:name, :email])} ,type: "notification_alarm"}}
    double = double("Notifier")
    expect(double).to receive(:notify).with(expected_args)
    allow(double).to receive(:app_name=)
    Notifier.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691", alarm: "I'm in danger",
                     :format => "json"}

    expect(response.status).to eq(200)
  end

  it "Member of a group sends alarm, the other members are notified with the current location" do
    load Rails.root + "db/seeds.rb"
    create_group_with_users
    group = Group.find_by_name("group1")
    member = User.find_by_email("user1@email.com")
    double = double("Notifier")
    expected_args = {reg_ids: ["creator_123","user2_123"], :data => {message: "user1 has sent an alarm!", :alarm_info => {message: "I'm in danger",
                                                                 location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z",
                                                                 sender: member.as_json(:only => [:name, :email])},type: "notification_alarm"}}
    expect(double).to receive(:notify).with(expected_args)
    allow(double). to receive(:app_name=)
    Notifier.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(member.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462", longitude: "-58.496691", alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(200)
  end

  it "Not a Member of a group sends alarm, access denied" do
    load Rails.root + "db/seeds.rb"
    create_group_with_users
    group = Group.find_by_name("group1")
    not_member = FactoryGirl.create(:user)
    double = double("Notifier")
    expect(double).not_to receive(:notify)
    expect(double).not_to receive(:app_name=)
    Notifier.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(not_member.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462", longitude: "-58.496691", alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(401)

  end

  it "Creator of a group sends alarm with zoom, the other members are notified with custom message and the current location with zoom" do
    load Rails.root + "db/seeds.rb"
    create_group_with_users
    group = Group.find_by_name("group1")
    creator = User.find_by_email("creator@email.com")
    double = double("Notifier")
    expected_args = {reg_ids: ["user1_123","user2_123"], :data => {message: "creator has sent an alarm!", :alarm_info=> {message: "I'm in danger",
                                                               location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,15z",
                                                               sender: creator.as_json(:only => [:name, :email]) },type: "notification_alarm"} }
    expect(double).to receive(:notify).with(expected_args)
    expect(double).to receive(:app_name=)
    Notifier.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691", zoom: "15" , alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(200)


  end

  it "Creator of a group, send alarms to group with no members, no push notification is sent" do
    load Rails.root + "db/seeds.rb"
    FactoryGirl.create(:user)
    user = User.first
    group = Group.new(name: "group_test")
    group.creator = user
    group.save
    group.reload
    double = double("Notifier")
    expect(double).not_to receive(:notify)
    expect(double).not_to receive(:app_name=)
    Notifier.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691" , alarm: "I'm in danger",
                              :format => "json"}
  end

  it "Creator of a group, send alarms to group with no members, message that group is empty is received" do
    load Rails.root + "db/seeds.rb"
    FactoryGirl.create(:user)
    user = User.first
    group = Group.new(name: "group_test")
    group.creator = user
    group.save
    group.reload

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691" , alarm: "I'm in danger",
                              :format => "json"}

    expect(json["message"]).to eq("The group has no members")
  end

end
