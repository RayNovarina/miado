class AddUidEmailToOmniauthProviders < ActiveRecord::Migration
  def change
    add_column :omniauth_providers, :uid_email, :string
    add_column :omniauth_providers, :uid_name, :string
  end
end
