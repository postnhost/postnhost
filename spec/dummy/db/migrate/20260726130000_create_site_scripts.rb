class CreateSiteScripts < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_site_scripts do |t|
      t.references :setting, null: false, foreign_key: { to_table: :postnhost_settings }
      t.string :placement, null: false
      t.text :script

      t.timestamps
    end
  end
end
