class CreateRegisteredTeams < ActiveRecord::Migration
  def change
    create_table :registered_teams do |t|
      t.string :name
      t.string :auth_token
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
