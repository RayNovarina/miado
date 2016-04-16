class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      t.string :name
      t.string :first_name
      t.string :last_name
      t.string :real_name_normalized
      t.string :image_72
      t.references :registered_team, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
