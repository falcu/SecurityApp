class CreateDevices < ActiveRecord::Migration
  def change
    create_table :devices do |t|
      t.belongs_to :user
      t.string :registration_id
      t.timestamps
    end
  end
end
