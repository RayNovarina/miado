class RemoveLastUpdatedFromChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :updated_by_slack_user_id, :string
  end
end
