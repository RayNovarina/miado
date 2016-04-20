class AddChannelToMembers < ActiveRecord::Migration
  def change
    add_reference :members, :channel, index: true, foreign_key: true
  end
end
