class CreatePageVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_page_variants do |t|
      t.string :title
      t.string :title_tag
      t.string :og_title
      t.string :meta_description
      t.text :content

      t.boolean :generating, default: false, null: false

      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.references :page, null: false, foreign_key: { to_table: :postnhost_pages }

      t.timestamps
    end

    add_index :postnhost_page_variants, %i[page_id language_id], unique: true
  end
end
