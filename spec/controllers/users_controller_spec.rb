require 'spec_helper'

describe UsersController do
  let(:user) { FactoryGirl.build(:user) }
  let(:json) { JSON.parse(response.body) }

  it "succesfully create an user" do
    post_user(user)
    expect(response.status).to eq(200)
    expect(User.first.name).to eq(user.name)
    expect(User.first.email).to eq(user.email)

  end

  it "succesfully create an user, json returned" do
    post_user(user)
    expect(response.status).to eq(200)
    expect(json["name"]).to eq(user.name)
    expect(json["email"]).to eq(user.email)
    expect(json["token"]).not_to be_nil
  end

end
