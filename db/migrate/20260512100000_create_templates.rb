class CreateTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_templates do |t|
      t.string :name, null: false, default: "default"

      t.timestamps
    end
  end
end
