class CreateChannels < ActiveRecord::Migration
  def change
    create_table :channels do |t|
      t.string :slack_id
      t.string :name
      t.references :member, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
