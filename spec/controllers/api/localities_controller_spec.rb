require 'spec_helper'

describe Api::LocalitiesController do
  let(:json) { JSON.parse(response.body) }

  before do
    load Rails.root + "db/seeds.rb"
    FactoryGirl.create(:user)
  end

  it "User notifies Olivos location, no previous record, freq with value 1" do
    user = User.first
    expected_locality = "Olivos"
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(user.token)
    put :notify_locality, {name: expected_locality, :format => "json"}
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
    user = User.first
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials("faketoken")
    put :notify_locality, {name: "Olivos", :format => "json"}

    expect(response.status).to eq(401)
    expect(user.frequencies.count).to eq(0)

  end



end
