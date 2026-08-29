class CreateArticles < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_articles do |t|
      t.string :title
      t.string :title_tag
      t.string :og_title
      t.string :schema_headline
      t.string :schema_article_type
      t.string :meta_description
      t.string :custom_excerpt
      t.string :auto_excerpt
      t.boolean :use_excerpt_as_meta_description, null: false, default: false
      t.text :content
      t.string :slug
      t.string :cover_image
      t.string :cover_image_alt
      t.boolean :top_pick, default: false, null: false
      t.datetime :scheduled_at
      t.string :scheduled_job_id
      t.text :publication_error
      t.integer :article_variants_count, default: 0, null: false

      t.references :user, null: true
      t.references :language, foreign_key: { to_table: :postnhost_languages }

      t.timestamps
    end

    add_index :postnhost_articles, :slug, unique: true
    add_index :postnhost_articles, :top_pick
    add_index :postnhost_articles, :scheduled_at
    add_index :postnhost_articles, :scheduled_job_id
  end
end
