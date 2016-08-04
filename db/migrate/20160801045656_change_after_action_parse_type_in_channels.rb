class ChangeAfterActionParseTypeInChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :after_action_parse_hash
    add_column :installations, :after_action_parse_hash, :jsonb
  end
end
