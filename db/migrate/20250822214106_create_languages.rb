class CreateLanguages < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_languages do |t|
      t.string :name
      t.string :html_lang
      t.boolean :default, default: false, null: false
      t.integer :articles_count, default: 0, null: false
      t.integer :article_variants_count, default: 0, null: false

      t.timestamps
    end

    add_index :postnhost_languages, :name, unique: true
    add_index :postnhost_languages, :html_lang, unique: true
  end
end
