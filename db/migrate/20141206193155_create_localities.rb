class CreateLocalities < ActiveRecord::Migration
  def change
    create_table :localities do |t|
      t.string :name, :unique => true, :null => false
      t.timestamps
    end
  end
end
