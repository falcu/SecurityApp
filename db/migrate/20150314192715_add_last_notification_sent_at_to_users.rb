class AddLastNotificationSentAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_notification_sent_at, :datetime
  end
end
