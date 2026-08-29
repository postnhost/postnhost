class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_users do |t|
      t.string :email, null: false, default: ""
      t.string :name
      t.string :slug, null: false
      t.string :position
      t.text :bio
      t.string :avatar_file
      t.string :website_url
      t.string :x_url
      t.string :linkedin_url
      t.string :facebook_url
      t.string :youtube_url
      t.string :instagram_url
      t.string :threads_url
      t.string :tiktok_url
      t.string :mastodon_url
      t.string :bluesky_url
      t.json :schema_profile, default: {}, null: false
      t.json :schema_locale_overrides, default: {}, null: false
      t.string :password_digest, null: false
      t.timestamps null: false
    end

    add_index :postnhost_users, :email, unique: true
    add_index :postnhost_users, :slug, unique: true
  end
end
