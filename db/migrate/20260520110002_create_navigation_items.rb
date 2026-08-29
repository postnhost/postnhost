class CreateNavigationItems < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_navigation_items do |t|
      t.references :navigation, null: false, foreign_key: { to_table: :postnhost_navigations }
      t.references :parent, foreign_key: { to_table: :postnhost_navigation_items }
      t.integer :container_kind, null: false
      t.integer :kind, null: false
      t.integer :target_kind
      t.integer :position, null: false, default: 0
      t.json :label_translations, null: false, default: {}
      t.bigint :target_id
      t.string :target_slug
      t.string :url
      t.boolean :nofollow, null: false, default: false

      t.timestamps
    end

    add_index :postnhost_navigation_items, %i[navigation_id container_kind position], name: "idx_postnhost_navigation_items_on_nav_container_position"
    add_index :postnhost_navigation_items, %i[parent_id position], name: "idx_postnhost_navigation_items_on_parent_position"
  end
end
