class AddUnsecureToLocalities < ActiveRecord::Migration
  def change
    add_column :localities, :unsecure, :boolean , default: false
  end
end
