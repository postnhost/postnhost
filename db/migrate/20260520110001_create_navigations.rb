class CreateNavigations < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_navigations do |t|
      t.references :setting, null: false, foreign_key: { to_table: :postnhost_settings }, index: { unique: true }

      t.timestamps
    end
  end
end
