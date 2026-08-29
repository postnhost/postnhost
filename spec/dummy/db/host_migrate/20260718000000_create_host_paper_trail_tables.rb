class CreateHostPaperTrailTables < ActiveRecord::Migration[7.2]
  TEXT_BYTES = 1_073_741_823

  def change
    create_table :host_posts do |t|
      t.string :title, null: false
      t.timestamps
    end

    create_table :versions do |t|
      t.string :whodunnit
      t.datetime :created_at
      t.bigint :item_id, null: false
      t.string :item_type, null: false
      t.string :event, null: false
      t.text :object, limit: TEXT_BYTES
      t.index %i[item_type item_id]
    end
  end
end
