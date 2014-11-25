class ChangeEmailUniqueInUsers < ActiveRecord::Migration
  def change
    change_column :users, :email, :string, :unique => true, :null => false
  end
end
