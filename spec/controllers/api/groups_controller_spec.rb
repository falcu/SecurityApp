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
    post_group(group,user)

    expect(response.status).to eq(200)
    groupDb = Group.first
    expect(groupDb.name).to eq(group.name)
    expect(groupDb.creator.email).to eq(user.email)
    expect(groupDb.creator.name).to eq(user.name)
    expect(groupDb.creator.id).to eq(user.id)
  end

  it "Create group, succesfull json expected" do
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    post_group(group,user)

    expect(response.status).to eq(200)
    expect(json["name"]).to eq(group.name)
  end

  it "Create group, wrong token, access denied" do
    user = FactoryGirl.build(:user)
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
    post_group(group,user)

    expect(Group.first).to be_nil
    expect(response.status).to eq(401)
  end

end
