class AddLocalityIdToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :locality, index: true
  end
end
