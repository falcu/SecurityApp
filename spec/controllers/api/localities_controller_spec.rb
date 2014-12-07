require 'spec_helper'
require 'net/http'

describe Api::LocalitiesController do
  let(:json) { JSON.parse(response.body) }
  let(:path) { Rails.root + "spec/fixtures/olivos.json" }

  before do
    load Rails.root + "db/seeds.rb"
    FactoryGirl.create(:user)
  end

  it "User notifies Olivos location, no previous record, freq with value 1" do
    expected_locality = "Olivos"
    expected_uri = URI.parse("http://maps.googleapis.com/maps/api/geocode/json?latlng=-34.510462,-58.496691&sensor=true_or_false")
    olivos_json = File.read(path)
    Net::HTTP.stub(:get).with(expected_uri).and_return(olivos_json)
    user = User.first

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    put :notify_locality, {latitude: "-34.510462", longitude: "-58.496691", :format => "json"}

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
    olivos_json = File.read(path)
    Net::HTTP.stub(:get).and_return(olivos_json)

    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
    put :notify_locality, {latitude: "-34.510462", longitude: "-58.496691", :format => "json"}

    user = User.first
    expect(response.status).to eq(401)
    expect(user.frequencies.count).to eq(0)

  end



end
