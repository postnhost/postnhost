class CreateApiTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_api_tokens do |t|
      t.references :user, null: false, foreign_key: { to_table: :postnhost_users }
      t.string :name, null: false
      t.string :token_digest, null: false
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :postnhost_api_tokens, :token_digest, unique: true
  end
end
