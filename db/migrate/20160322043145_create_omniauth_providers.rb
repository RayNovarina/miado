class CreateOmniauthProviders < ActiveRecord::Migration
  def change
    create_table :omniauth_providers do |t|
      t.references :user, index: true, foreign_key: true
      t.string :name
      t.string :uid
      t.string :auth_token
      t.jsonb :auth_json
      t.jsonb :auth_params_json

      t.timestamps null: false
    end
  end
end
