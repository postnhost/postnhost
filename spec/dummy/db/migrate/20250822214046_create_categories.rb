class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_categories do |t|
      t.string :name
      t.string :slug
      t.string :meta_description
      t.integer :articles_count, default: 0, null: false

      t.timestamps
    end

    add_index :postnhost_categories, :name, unique: true
    add_index :postnhost_categories, :slug, unique: true
  end
end
