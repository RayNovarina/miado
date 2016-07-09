class AddUpdatedByToListItems < ActiveRecord::Migration
  def change
    add_column :list_items, :updated_by_slack_user_id, :string
  end
end
