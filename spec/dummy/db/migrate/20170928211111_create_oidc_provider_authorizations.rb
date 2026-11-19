# frozen_string_literal: true

class CreateOIDCProviderAuthorizations < ActiveRecord::Migration[7.0]
  def change
    create_table :oidc_provider_authorizations do |t|
      t.integer :account_id, null: false
      t.index :account_id
      t.string :client_id, null: false
      t.string :nonce
      t.string :code, null: false
      t.text :scopes, null: false
      t.text :claims
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :oidc_provider_authorizations, :client_id
    add_index :oidc_provider_authorizations, :code, unique: true
  end
end
