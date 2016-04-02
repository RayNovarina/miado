class DropUnusedTables < ActiveRecord::Migration
  def change
    drop_table :events
    drop_table :registered_applications
  end
end
