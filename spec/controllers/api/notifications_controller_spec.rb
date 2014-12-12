require 'spec_helper'

describe Api::NotificationsController do

  let(:app) { Rpush::Gcm::App.find_by_name("android_app") }

  before do
    load Rails.root + "db/seeds.rb"
    create_group_with_users
    create_app_for_push_notification
  end

  it "Creator of a group sends alarm, the other members are notified with custom message and the current location" do
    group = Group.find_by_name("group1")
    creator = User.find_by_email("creator@email.com")
    double = double("Rpush::Gcm::Notification")
    expect(double).to receive(:data=).with(message: "I'm in danger", location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z")
    expect(double).to receive(:registration_ids=).with(["token","user1_123,user2_123"])
    expect(double).to receive(:app=).with(app)
    allow(double).to receive(:save!)
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691", alarm: "I'm in danger",
                     :format => "json"}

    expect(response.status).to eq(200)


  end

  it "Member of a group sends alarm, the other members are notified with the current location" do
    group = Group.find_by_name("group1")
    member = User.find_by_email("user1@email.com")
    double = double("Rpush::Gcm::Notification")
    expect(double).to receive(:data=).with(message: "I'm in danger", location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z")
    expect(double).to receive(:registration_ids=).with(["token","creator_123,user2_123"])
    allow(double).to receive(:save!)
    expect(double).to receive(:app=).with(app)
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(member.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462", longitude: "-58.496691", alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(200)


  end

  it "Not a Member of a group sends alarm, access denied" do
    group = Group.find_by_name("group1")
    not_member = FactoryGirl.create(:user)
    double = double("Rpush::Gcm::Notification")
    expect(double).not_to receive(:data=).with(message: "I'm in danger", location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z")
    expect(double).not_to receive(:registration_ids=)
    expect(double).not_to receive(:save!)
    expect(double).not_to receive(:app=)
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(not_member.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462", longitude: "-58.496691", alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(401)

  end

  it "Creator of a group sends alarm with zoom, the other members are notified with custom message and the current location with zoom" do
    group = Group.find_by_name("group1")
    creator = User.find_by_email("creator@email.com")
    double = double("Rpush::Gcm::Notification")
    expect(double).to receive(:data=).with(message: "I'm in danger", location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,15z")
    expect(double).to receive(:registration_ids=).with(["token","user1_123,user2_123"])
    allow(double).to receive(:save!)
    expect(double).to receive(:app=).with(app)
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(creator.token)
    post :send_notification ,{group_id: group.id, latitude: "-34.510462" , longitude: "-58.496691", zoom: "15" , alarm: "I'm in danger",
                   :format => "json"}

    expect(response.status).to eq(200)


  end

end
