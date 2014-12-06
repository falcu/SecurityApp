class CreateFrequencies < ActiveRecord::Migration
  def change
    create_table :frequencies do |t|
      t.integer :user_id, :locality_id
      t.integer :value, :default => 0
    end
  end
end
