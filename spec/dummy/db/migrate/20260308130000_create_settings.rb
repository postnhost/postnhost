class CreateSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_settings do |t|
      t.string :site_logo
      t.string :og_image
      t.string :site_url
      t.integer :public_page_size
      t.string :timezone
      t.string :site_indexing, default: "index", null: false
      t.json :locale_overrides, default: {}, null: false
      t.json :schema_settings, default: {}, null: false
      t.json :schema_locale_overrides, default: {}, null: false
      t.boolean :use_auto_header_navigation, default: true, null: false
      t.boolean :use_auto_footer_navigation, default: true, null: false
      t.boolean :author_pages_enabled, default: true, null: false
      t.boolean :show_powered_by, default: true, null: false
      t.boolean :search_enabled, default: true, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
  end
end
