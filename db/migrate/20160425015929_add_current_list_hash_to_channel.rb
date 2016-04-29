class AddCurrentListHashToChannel < ActiveRecord::Migration
  def change
    enable_extension 'hstore'
    add_column :channels, :current_list_parse_hash_json, :hstore
  end
end
