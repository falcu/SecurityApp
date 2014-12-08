require 'spec_helper'

describe Api::UsersController do
  let(:user) { FactoryGirl.build(:user) }
  let(:bad_user) { FactoryGirl.build(:user, email: "") }
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
    expect(response.status).to eq(400)
    expect(json["error"]).to eq("Unable to save user")
  end

  it "Two users with same email, second user should not be created" do
    post_user(user)
    expect(response.status).to eq(200)
    post_user(user)
    expect(response.status).to eq(400)
  end

  it "Sign in with correct credentials" do
    new_user = FactoryGirl.create(:user)
    post :sign_in , {:user => {:email => user.email, :password => user.password},
                    :format => "json"}
    expect(response.status).to eq(200)
    expect(json["token"]).to eq(new_user.token)
  end

  it "Sign in with bad credentials, access denied" do
    FactoryGirl.create(:user)
    post :sign_in , {:user => {:email => user.email, :password => "badpassword"},
                     :format => "json"}
    expect(response.status).to eq(401)
    expect(json["token"]).to be_nil
  end

  it "Sign in with nonexistent email, access denied" do
    new_user = FactoryGirl.create(:user)
    post :sign_in , {:user => {:email => "fakeemail", :password => new_user.password},
                     :format => "json"}
    expect(response.status).to eq(401)
    expect(json["token"]).to be_nil
  end


end
