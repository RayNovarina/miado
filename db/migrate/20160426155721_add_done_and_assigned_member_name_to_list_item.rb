class AddDoneAndAssignedMemberNameToListItem < ActiveRecord::Migration
  def change
    add_column :list_items, :assigned_member_name, :string
    add_column :list_items, :done, :boolean
  end
end
