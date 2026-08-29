class CreateArticleSuggestions < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_article_suggestions do |t|
      t.references :article, null: false, foreign_key: { to_table: :postnhost_articles }
      t.references :suggested_article, null: false, foreign_key: { to_table: :postnhost_articles }
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :postnhost_article_suggestions, %i[article_id suggested_article_id], unique: true
  end
end
