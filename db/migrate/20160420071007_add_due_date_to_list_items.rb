class AddDueDateToListItems < ActiveRecord::Migration
  def change
    add_column :list_items, :assigned_member_id, :string
    add_column :list_items, :assigned_due_date, :datetime
  end
end
