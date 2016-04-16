class CreateListItems < ActiveRecord::Migration
  def change
    create_table :list_items do |t|
      t.string :description
      t.datetime :due_date
      t.references :channel, index: true, foreign_key: true
      t.references :member, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
