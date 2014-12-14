class CreateCustomSecureLocalities < ActiveRecord::Migration
  def change
    create_table :custom_secure_localities do |t|
      t.integer :user_id
      t.integer :locality_id
    end
  end
end
