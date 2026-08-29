class CreateArticleVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_article_variants do |t|
      t.string :title
      t.string :title_tag
      t.string :og_title
      t.string :schema_headline
      t.string :meta_description
      t.string :custom_excerpt
      t.string :auto_excerpt
      t.boolean :use_excerpt_as_meta_description, null: false, default: false
      t.text :content

      t.boolean :generating, default: false, null: false

      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.references :article, null: false, foreign_key: { to_table: :postnhost_articles }

      t.timestamps
    end

    add_index :postnhost_article_variants, %i[article_id language_id], unique: true
  end
end
