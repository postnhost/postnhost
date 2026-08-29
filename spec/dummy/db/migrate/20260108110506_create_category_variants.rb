class CreateCategoryVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_category_variants do |t|
      t.references :category, null: false, foreign_key: { to_table: :postnhost_categories }
      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.string :name
      t.string :meta_description
      t.boolean :generating, default: false, null: false

      t.timestamps
    end

    add_index :postnhost_category_variants, %i[category_id language_id], unique: true
  end
end
