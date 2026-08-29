class CreateArticleAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_article_authors do |t|
      t.references :article, null: false, foreign_key: { to_table: :postnhost_articles }
      t.references :user, null: false, foreign_key: { to_table: :postnhost_users }
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :postnhost_article_authors, %i[article_id user_id], unique: true
    add_index :postnhost_article_authors, %i[article_id position]
  end
end
