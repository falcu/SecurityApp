require 'spec_helper'

describe UsersController do
  let(:user) { FactoryGirl.build(:user) }
  let(:json) { JSON.parse(response.body) }

  it "succesfully create an user" do
    create_post(user)
    expect(response.status).to eq(200)
    expect(User.first.name).to eq(user.name)
    expect(User.first.email).to eq(user.email)

  end

  it "succesfully create an user, json returned" do
    create_post(user)
    expect(response.status).to eq(200)
    expect(json["name"]).to eq("username")
    expect(json["email"]).to eq("user@address.com")
  end

end
