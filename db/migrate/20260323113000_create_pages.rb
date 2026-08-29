class CreatePages < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_pages do |t|
      t.references :user, null: false, foreign_key: { to_table: :postnhost_users }
      t.string :title
      t.string :title_tag
      t.string :og_title
      t.string :meta_description
      t.text :content
      t.string :slug
      t.integer :page_variants_count, default: 0, null: false
      t.references :language, null: true, foreign_key: { to_table: :postnhost_languages }

      t.timestamps
    end

    add_index :postnhost_pages, :slug, unique: true
  end
end
