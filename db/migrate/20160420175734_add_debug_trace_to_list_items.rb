class AddDebugTraceToListItems < ActiveRecord::Migration
  def change
    add_column :list_items, :debug_trace, :string
  end
end
