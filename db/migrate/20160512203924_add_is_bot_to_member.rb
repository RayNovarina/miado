class AddIsBotToMember < ActiveRecord::Migration
  def change
    add_column :members, :is_bot, :boolean, default: false
  end
end
