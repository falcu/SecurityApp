require 'spec_helper'

describe "Notifier" do

  let(:notifier) { Notifier.new }

  it 'Given a notifier, when send notification, all mandatory setters are called' do
    double = double("Rpush::Gcm::Notification")
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    expect(double).to receive(:app=)
    expect(double).to receive(:registration_ids=)
    expect(double).to receive(:data=)
    expect(double).to receive(:save!)
    notifier.notify(app_name: "app_name", reg_ids: "123", data: "data")
  end

  it 'Given a notifier, when send notification with no app_name and is not previously defined, exception is raised' do
    expect{
      notifier.notify(reg_ids: "123", data: "data")}.to raise_error(ArgumentError)
  end

  it 'Given a notifier, when send notification with no reg_ids, exception is raised' do
    expect{
      notifier.notify(app_name: "app_name", data: "data")}.to raise_error(ArgumentError)
  end

  it 'Given a notifier, when send notification with no data, exception is raised' do
    expect{
      notifier.notify(reg_ids: "123", data: "data")}.to raise_error(ArgumentError)
  end

  it 'Given a notifier, app_name is set and notify is called, message sent' do
    notifier.app_name = "app_name"
    double = double("Rpush::Gcm::Notification")
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    expect(double).to receive(:app=)
    expect(double).to receive(:registration_ids=)
    expect(double).to receive(:data=)
    expect(double).to receive(:save!)
    notifier.notify(reg_ids: "123", data: "data")
  end

  it 'Given a notifier, notify with correct args, registration_ids array is set' do
    notifier.app_name = "app_name"
    double = double("Rpush::Gcm::Notification")
    Rpush::Gcm::Notification.stub(:new).and_return(double)

    allow(double).to receive(:app=)
    expect(double).to receive(:registration_ids=).with(["token","123"])
    allow(double).to receive(:data=)
    allow(double).to receive(:save!)
    notifier.notify(app_name: "app_name", reg_ids: "123", data: "data")
  end
end