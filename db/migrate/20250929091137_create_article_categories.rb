class CreateArticleCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_article_categories do |t|
      t.references :article, null: false, foreign_key: { to_table: :postnhost_articles }
      t.references :category, null: false, foreign_key: { to_table: :postnhost_categories }

      t.timestamps
    end

    add_index :postnhost_article_categories, %i[article_id category_id], unique: true
  end
end
