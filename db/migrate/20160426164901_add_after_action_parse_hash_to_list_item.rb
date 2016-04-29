class AddAfterActionParseHashToListItem < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
    add_column :channels, :after_action_parse_hash, :hstore
  end
end
