class RemoveAssignedMemberNameFromListItems < ActiveRecord::Migration
  def change
    remove_column :list_items, :assigned_member_name
  end
end
