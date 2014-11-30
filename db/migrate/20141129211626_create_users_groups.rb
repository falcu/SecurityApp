class CreateUsersGroups < ActiveRecord::Migration
  def change
    create_table :users_groups, id: false do |t|
      t.integer :user_id, :group_id
    end
  end
end
