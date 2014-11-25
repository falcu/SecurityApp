require 'spec_helper'

describe UsersController do
  let(:user) { FactoryGirl.build(:user) }
  let(:bad_user) { FactoryGirl.build(:user,email: "") }
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

  it "bad user with no email" do
    post_user(bad_user)
    expect(response.status).to eq(401)
    expect(json["message"]).to eq("Unable to save user")
  end

  it "Two users with same email, second user should not be created" do
  post_user(user)
  expect(response.status).to eq(200)
  post_user(user)
  expect(response.status).to eq(401)
  end

end
