class CreateCustomInsecureLocalities < ActiveRecord::Migration
  def change
    create_table :custom_insecure_localities do |t|
      t.integer :user_id
      t.integer :locality_id
    end
  end
end
