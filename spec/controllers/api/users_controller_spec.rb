require 'spec_helper'

describe Api::UsersController do
  let(:user) { FactoryGirl.build(:user) }
  let(:bad_user) { FactoryGirl.build(:user, email: "") }
  let(:json) { JSON.parse(response.body) }

  context "Create a user" do

    it "Succesfully create a user" do
      create_user(user)
      expect(response.status).to eq(200)
      expect(User.first.name).to eq(user.name)
      expect(User.first.email).to eq(user.email)

    end

    it "Succesfully create a user, json returned with token" do
      create_user(user)
      expect(response.status).to eq(200)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["token"]).not_to be_nil
    end

    it "Try to create bad user with no email, error returned" do
      create_user(bad_user)
      expect(response.status).to eq(400)
      expect(json["error"]).to eq("Unable to save user")
    end

    it "Create a user, try to create second user with same email, second user should not be created" do
      create_user(user)
      expect(response.status).to eq(200)
      create_user(user)
      expect(response.status).to eq(400)
    end

    it "succesfully create a user, specifying a register_id" do
      expected_device_id = "device_id"
      post :create, {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password},
                     :device => {:registration_id => expected_device_id},
                     :format => "json"}
      saved_user = User.first
      expect(response.status).to eq(200)
      expect(saved_user.name).to eq(user.name)
      expect(saved_user.email).to eq(user.email)
      expect(saved_user.devices.first.registration_id).to eq(expected_device_id)

    end

    it "Create user with reg id, then sign in with same reg id, the second time should be ignored" do
      registration_id = "reg_id"
      new_user = FactoryGirl.build(:user)
      new_user.devices << Device.new(registration_id: registration_id)
      new_user.save

      expect(new_user.devices.count).to eq(1)

      post :sign_in, {:user => {:email => user.email, :password => user.password},
                      :device => {:registration_id => registration_id},
                      :format => "json"}
      new_user.reload

      expect(response.status).to eq(200)
      expect(new_user.devices.count).to eq(1)
      expect(new_user.devices.first.registration_id).to eq(registration_id)

    end

    it "Create user with reg id, then sign in with different reg id, the second should be saved" do
      registration_id1 = "reg_id1"
      registration_id2 = "reg_id2"
      new_user = FactoryGirl.build(:user)
      new_user.devices << Device.new(registration_id: registration_id1)
      new_user.save

      expect(new_user.devices.count).to eq(1)

      post :sign_in, {:user => {:email => user.email, :password => user.password},
                      :device => {:registration_id => registration_id2},
                      :format => "json"}
      new_user.reload

      expect(response.status).to eq(200)
      expect(new_user.devices.count).to eq(2)

    end

    it "Create user, json returned but password_digest is not included" do
      create_user(user)
      expect(response.status).to eq(200)
      expect(json["password_digest"]).to be_nil
    end

  end

  context "Sign in" do

    it "Sign in with correct credentials" do
      new_user = FactoryGirl.create(:user)
      post :sign_in, {:user => {:email => user.email, :password => user.password},
                      :format => "json"}
      expect(response.status).to eq(200)
      expect(json["user"]["token"]).to eq(new_user.token)
    end

    it "Sign in with bad credentials, access denied" do
      FactoryGirl.create(:user)
      post :sign_in, {:user => {:email => user.email, :password => "badpassword"},
                      :format => "json"}
      expect(response.status).to eq(401)
      expect(json["user"]).to be_nil
    end

    it "Sign in with nonexistent email, access denied" do
      new_user = FactoryGirl.create(:user)
      post :sign_in, {:user => {:email => "fakeemail", :password => new_user.password},
                      :format => "json"}
      expect(response.status).to eq(401)
      expect(json["user"]).to be_nil
    end

    it "Sign in specifying a register_id, it should be saved" do
      new_user = FactoryGirl.create(:user)
      expected_device_id = "device_id"
      expect(new_user.devices.count).to eq(0)

      post :sign_in, {:user => {:email => user.email, :password => user.password},
                      :device => {:registration_id => expected_device_id},
                      :format => "json"}
      new_user.reload

      expect(response.status).to eq(200)
      expect(new_user.devices.count).to eq(1)
      expect(new_user.devices.first.registration_id).to eq(expected_device_id)

    end

  end

  context "Sign_in or create" do

    it "Succesfuly create user" do
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                      :format => "json"}
      expect(response.status).to eq(200)
      expect(User.first.name).to eq(user.name)
      expect(User.first.email).to eq(user.email)
    end

    it "Sign in existing user" do
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                                 :format => "json"}
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                                 :format => "json"}
      expect(response.status).to eq(200)
      expect(User.count).to eq(1)
      expect(User.first.name).to eq(user.name)
      expect(User.first.email).to eq(user.email)
    end

    it "Succesfuly create user, json with token returned" do
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                                 :format => "json"}
      expect(response.status).to eq(200)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["token"]).not_to be_nil
    end

    it "Succesfuly sign_in user, json with token returned" do
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                                 :format => "json"}
      post :create_or_sign_in , {:user => {:name => user.name, :email => user.email, :password => user.password, :password_confirmation => user.password },
                                 :format => "json"}
      expect(response.status).to eq(200)
      expect(json["user"]["name"]).to eq(user.name)
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["token"]).not_to be_nil
    end
  end


end
