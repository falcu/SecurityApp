class ChangeUnsecureToInsecureLocalities < ActiveRecord::Migration
  def self.up
    rename_column :localities, :unsecure, :insecure
  end

  def self.down
    rename_column :localities, :insecure, :unsecure
  end
end
