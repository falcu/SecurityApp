require 'spec_helper'
require 'net/http'

describe Api::LocalitiesController do
  let(:json) { JSON.parse(response.body) }
  let(:olivos_path) { Rails.root + "spec/fixtures/olivos.json" }
  let(:martinez_path) { Rails.root + "spec/fixtures/martinez.json" }
  let(:invalid_path) { Rails.root + "spec/fixtures/invalid_coordinates.json" }

  context "Notify Locality" do

    before do
      load Rails.root + "db/seeds.rb"
      create_group_with_users
      FactoryGirl.create(:user)
    end

    it "User notifies Olivos location, no previous record, freq with value 1" do
      expected_locality = "Olivos"
      expected_uri = URI.parse("http://maps.googleapis.com/maps/api/geocode/json?latlng=-34.510462,-58.496691&sensor=true_or_false")
      olivos_json = File.read(olivos_path)
      Net::HTTP.stub(:get).with(expected_uri).and_return(olivos_json)
      user = User.first

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      notify_locality("-34.510462", "-58.496691")

      user.reload
      olivos_locality = Locality.find_by_name("Olivos")
      frequency = user.frequencies.find_by_locality_id(olivos_locality.id)
      expect(response.status).to eq(200)
      expect(user.localities.first.name).to eq(expected_locality)
      expect(user.localities.count).to eq(1)
      expect(frequency.value).to eq(1)
      expect(frequency.user_id).to eq(user.id)
      expect(frequency.locality_id).to eq(olivos_locality.id)

    end

    it "Fake user notifies location, access denied" do
      olivos_json = File.read(olivos_path)
      Net::HTTP.stub(:get).and_return(olivos_json)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      notify_locality("-34.510462", "-58.496691")

      user = User.first
      expect(response.status).to eq(401)
      expect(user.frequencies.count).to eq(0)

    end

    it "User notifies Olivos location, previous record with value 3, freq increase to 4" do
      expected_locality = "Olivos"
      expected_uri = URI.parse("http://maps.googleapis.com/maps/api/geocode/json?latlng=-34.510462,-58.496691&sensor=true_or_false")
      olivos_json = File.read(olivos_path)
      Net::HTTP.stub(:get).with(expected_uri).and_return(olivos_json)
      user = User.first
      olivos_locality = Locality.find_by_name("Olivos")
      user.frequencies.build(locality_id: olivos_locality.id, value: 3)
      user.save

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      notify_locality("-34.510462", "-58.496691")

      user.reload

      frequency = user.frequencies.find_by_locality_id(olivos_locality.id)
      expect(response.status).to eq(200)
      expect(user.localities.first.name).to eq(expected_locality)
      expect(user.localities.count).to eq(1)
      expect(frequency.value).to eq(4)
      expect(frequency.user_id).to eq(user.id)
      expect(frequency.locality_id).to eq(olivos_locality.id)

    end

    it "User notifies invalid location, error" do
      invalid_coordinates = File.read(invalid_path)
      olivos_locality = Locality.find_by_name("Olivos")
      Net::HTTP.stub(:get).and_return(invalid_coordinates)
      user = User.first

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      notify_locality("invalid", "invalid")

      frequency = user.frequencies.find_by_locality_id(olivos_locality.id)
      expect(frequency).to be_nil
      expect(user.localities.first).to be_nil
      expect(response.status).to eq(400)
    end

    it "User notifies unsecure location which is not custom secure, a push notification is sent to all the members of the group" do
      martinez = File.read(martinez_path)
      Net::HTTP.stub(:get).and_return(martinez)
      user = User.find_by_email("user1@email.com")
      group = Group.find_by_name("group1")

      expected_args = {reg_ids: ["creator_123","user2_123"], :data => {message: "user1 entered Martinez which is considered unsecured",
                                                                   location: "https://www.google.com.ar/maps/@-34.494271,-58.498217,20z", type: "notify_unsecure_location"}}
      double = double("Notifier")
      expect(double).to receive(:notify).with(expected_args)
      allow(double).to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :notify_locality, {latitude: "-34.494271", longitude: "-58.498217", group_id: group.id, :format => "json"}
    end

    it "User notifies unsecure location but it's custom secure, nothing is sent" do
      martinez = File.read(martinez_path)
      Net::HTTP.stub(:get).and_return(martinez)
      user = User.find_by_email("user1@email.com")
      group = Group.find_by_name("group1")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

      double = double("Notifier")
      expect(double).not_to receive(:notify)
      expect(double).not_to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :notify_locality, {latitude: "-34.494271", longitude: "-58.498217", group_id: group.id, :format => "json"}
    end

    it "User notifies secure location but it's custom insecure, notification is sent to the group" do
      olivos = File.read(olivos_path)
      Net::HTTP.stub(:get).and_return(olivos)
      user = User.find_by_email("user1@email.com")
      group = Group.find_by_name("group1")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Olivos", :format => "json"}

      expected_args = {reg_ids: ["creator_123","user2_123"], :data => {message: "user1 entered Olivos which is considered unsecured",
                                                                   location: "https://www.google.com.ar/maps/@-34.510462,-58.496691,20z", type: "notify_unsecure_location"}}
      double = double("Notifier")
      expect(double).to receive(:notify).with(expected_args)
      expect(double).to receive(:app_name=)
      Notifier.stub(:new).and_return(double)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :notify_locality, {latitude: "-34.510462", longitude: "-58.496691", group_id: group.id, :format => "json"}
    end

  end

  context "Set custom secure/unsecure locality with correct credentials" do

    before do
      load Rails.root + "db/seeds.rb"
    end

    it "User with correct credentials set custom secure locality, locality added to list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

      expect(response.status).to eq(200)
      expect(user.custom_secure_localities.count).to eq(1)
      expect(user.custom_secure_localities.first.name).to eq("Martinez")
    end

    it "User with correct credentials set same custom secure locality twice, locality added to list once" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(user.custom_secure_localities.count).to eq(1)
      expect(user.custom_secure_localities.first.name).to eq("Martinez")
    end

    it "User with incorrect credentials, set custom secure locality, access denied" do
      FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(401)
      expect(user.custom_secure_localities.count).to eq(0)
    end

    it "User with correct credentials, set unknown custom secure locality, json with error returned" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token )
      put :set_secure_locality, {locality_name: "Unknown", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(400)
      expect(user.custom_secure_localities.count).to eq(0)
    end

    it "User with correct credentials, set custom secure locality, json returned" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}


      expect(response.status).to eq(200)
      expect(json["message"]).to eq("You set Martinez as a secure locality")
      expect(json["type"]).to eq("set_secure_locality")
    end

    it "User with correct credentials, set custom secure locality using id, locality added to list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      locality = Locality.find_by_name("Martinez")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {id: locality.id, :format => "json"}

      expect(response.status).to eq(200)
      expect(user.custom_secure_localities.count).to eq(1)
      expect(user.custom_secure_localities.first.name).to eq("Martinez")
    end

    it "User with correct credentials, set custom secure locality using id, json returned" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      locality = Locality.find_by_name("Martinez")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {id: locality.id, :format => "json"}

      expect(response.status).to eq(200)
      expect(json["message"]).to eq("You set Martinez as a secure locality")
      expect(json["type"]).to eq("set_secure_locality")
    end

    it "User with correct credentials, set custom insecure locality, locality added to list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(user.custom_insecure_localities.count).to eq(1)
      expect(user.custom_insecure_localities.first.name).to eq("Martinez")
    end

    it "User with correct credentials, set custom insecure locality, json returned" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(json["message"]).to eq("You set Martinez as an insecure locality")
      expect(json["type"]).to eq("set_insecure_locality")
    end

    it "User with correct credentials set same custom insecure locality twice, locality added to list once" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(user.custom_insecure_localities.count).to eq(1)
      expect(user.custom_insecure_localities.first.name).to eq("Martinez")
    end

    it "User with incorrect credentials, set custom insecure locality, access denied" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(401)
      expect(user.custom_insecure_localities.count).to eq(0)
    end

    it "User with correct credentials, set custom insecure locality using id, locality added to list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      locality = Locality.find_by_name("Martinez")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {id: locality.id, :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(user.custom_insecure_localities.count).to eq(1)
      expect(user.custom_insecure_localities.first.name).to eq("Martinez")
    end

    it "User with correct credentials, set custom insecure locality using id, json returned" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      locality = Locality.find_by_name("Martinez")

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {id: locality.id, :format => "json"}
      user = User.find_by_name("user")

      expect(response.status).to eq(200)
      expect(json["message"]).to eq("You set Martinez as an insecure locality")
      expect(json["type"]).to eq("set_insecure_locality")
    end

    it "User adds Martinez as insecure and then adds Martinez as secure, Martinez should only be in the secure list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}

      expect(user.custom_insecure_localities.count). to eq(1)
      expect(user.custom_secure_localities.count). to eq(0)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

      expect(user.custom_insecure_localities.count). to eq(0)
      expect(user.custom_secure_localities.count). to eq(1)
    end

    it "User adds Martinez as secure and then adds Martinez as insecure, Martinez should only be in the insecure list" do
      user = FactoryGirl.create(:user, :name => "user", :email => "user@someemail.com", :password => "123456")
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

      expect(user.custom_secure_localities.count). to eq(1)
      expect(user.custom_insecure_localities.count). to eq(0)

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}

      expect(user.custom_secure_localities.count). to eq(0)
      expect(user.custom_insecure_localities.count). to eq(1)
    end

  end

  context "Get localities" do
      let(:user) {  FactoryGirl.create(:user) }


    it "A user with incorrect token requests the localities, access denied" do

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("fake")
      get :get_localities, {:format => "json"}

      expect(response.status).to eq(401)
    end

    it "A legitimate user request localities and there is only 1" do
      locality = FactoryGirl.create(:locality, :name => "Olivos")
      expected_result = [locality].collect { |l| l.as_json(:only => [:id, :name]) }

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
      get :get_localities, {:format => "json"}

      expect(json["localities_info"]).not_to be_nil
      expect(json["localities_info"]).to eq(expected_result)
    end

      it "A legitimate user request localities and there are 2" do
        locality1 = FactoryGirl.create(:locality, :name => "Olivos")
        locality2 = FactoryGirl.create(:locality, :name => "Martinez")
        expected_result = [locality1,locality2].collect { |l| l.as_json(:only => [:id, :name]) }

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        get :get_localities, {:format => "json"}

        expect(json["localities_info"]).not_to be_nil
        expect(json["localities_info"]).to eq(expected_result)
      end

      it "A user with incorrect token requests his/her secured localities, access denied" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("fake")
        get :get_secure_localities, {:format => "json"}

        expect(response.status).to eq(401)
      end

      it "A legitimate user requests his/her 1 secured localities" do
        FactoryGirl.create(:locality, :name => "Martinez")
        FactoryGirl.create(:locality, :name => "Olivos")

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        get :get_secure_localities, {:format => "json"}

        expected_response = user.custom_secure_localities.collect { |l| l.as_json(:only => [:id, :name]) }

        expect(json["localities_info"]).not_to be_nil
        expect(json["localities_info"]).to eq(expected_response)
      end

      it "A legitimate user requests his/her 2 secured localities" do
        FactoryGirl.create(:locality, :name => "Martinez")
        FactoryGirl.create(:locality, :name => "Olivos")
        FactoryGirl.create(:locality, :name => "La Lucila")

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_secure_locality, {locality_name: "Martinez", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_secure_locality, {locality_name: "La Lucila", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        get :get_secure_localities, {:format => "json"}

        expected_response = user.custom_secure_localities.collect { |l| l.as_json(:only => [:id, :name]) }

        expect(json["localities_info"]).not_to be_nil
        expect(json["localities_info"]).to eq(expected_response)
      end

      it "A user with incorrect token requests his/her insecured localities, access denied" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("fake")
        get :get_insecure_localities, {:format => "json"}

        expect(response.status).to eq(401)
      end

      it "A legitimate user requests his/her 1 insecured localities" do
        FactoryGirl.create(:locality, :name => "Martinez")
        FactoryGirl.create(:locality, :name => "Olivos")

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        get :get_insecure_localities, {:format => "json"}

        expected_response = user.custom_insecure_localities.collect { |l| l.as_json(:only => [:id, :name]) }

        expect(json["localities_info"]).not_to be_nil
        expect(json["localities_info"]).to eq(expected_response)
      end

      it "A legitimate user requests his/her 2 insecured localities" do
        FactoryGirl.create(:locality, :name => "Martinez")
        FactoryGirl.create(:locality, :name => "Olivos")
        FactoryGirl.create(:locality, :name => "La Lucila")

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_insecure_locality, {locality_name: "Martinez", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        put :set_insecure_locality, {locality_name: "La Lucila", :format => "json"}

        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
        get :get_insecure_localities, {:format => "json"}

        expected_response = user.custom_insecure_localities.collect { |l| l.as_json(:only => [:id, :name]) }

        expect(json["localities_info"]).not_to be_nil
        expect(json["localities_info"]).to eq(expected_response)
      end


  end


end
