class CreateSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :postnhost_article_snapshots do |t|
      t.references :article, null: false, index: { unique: true },
                             foreign_key: { to_table: :postnhost_articles, on_delete: :cascade }
      t.references :paper_trail_version, null: false, index: { unique: true },
                                         foreign_key: { to_table: :postnhost_versions, on_delete: :restrict }
      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.string :title, null: false
      t.string :title_tag
      t.string :og_title
      t.string :schema_headline
      t.string :schema_article_type
      t.string :meta_description
      t.string :custom_excerpt
      t.string :auto_excerpt
      t.boolean :use_excerpt_as_meta_description, null: false, default: false
      t.text :content, null: false
      t.string :slug, null: false
      t.string :cover_image_identifier
      t.string :cover_image_alt
      t.boolean :top_pick, null: false, default: false
      t.datetime :published_at, null: false
      t.timestamps null: false
    end

    add_index :postnhost_article_snapshots, :slug, unique: true
    add_index :postnhost_article_snapshots, %i[language_id published_at],
              name: "idx_postnhost_article_snapshots_language"
    add_index :postnhost_article_snapshots, %i[top_pick language_id published_at],
              name: "idx_postnhost_article_snapshots_top_picks"
    add_index :postnhost_article_snapshots, :updated_at

    create_table :postnhost_article_snapshot_categories do |t|
      t.references :article_snapshot, null: false, index: { name: "idx_postnhost_snapshot_categories_article" },
                                      foreign_key: { to_table: :postnhost_article_snapshots, on_delete: :cascade }
      t.references :category, null: false, foreign_key: { to_table: :postnhost_categories }
      t.timestamps null: false
    end

    add_index :postnhost_article_snapshot_categories, %i[article_snapshot_id category_id],
              unique: true, name: "idx_postnhost_snapshot_categories_unique"
    add_index :postnhost_article_snapshot_categories, %i[category_id article_snapshot_id],
              name: "idx_postnhost_snapshot_categories_reverse"

    create_table :postnhost_article_snapshot_authors do |t|
      t.references :article_snapshot, null: false, index: { name: "idx_postnhost_snapshot_authors_article" },
                                      foreign_key: { to_table: :postnhost_article_snapshots, on_delete: :cascade }
      t.references :user, null: false, foreign_key: { to_table: :postnhost_users }
      t.integer :position, null: false
      t.timestamps null: false
    end

    add_index :postnhost_article_snapshot_authors, %i[article_snapshot_id user_id],
              unique: true, name: "idx_postnhost_snapshot_authors_unique"
    add_index :postnhost_article_snapshot_authors, %i[article_snapshot_id position],
              unique: true, name: "idx_postnhost_snapshot_authors_position"
    add_index :postnhost_article_snapshot_authors, %i[user_id article_snapshot_id],
              name: "idx_postnhost_snapshot_authors_reverse"
    add_check_constraint :postnhost_article_snapshot_authors, "position >= 0",
                         name: "postnhost_snapshot_author_position_nonnegative"

    create_table :postnhost_article_snapshot_suggestions do |t|
      t.references :article_snapshot, null: false, index: { name: "idx_postnhost_snapshot_suggestions_article" },
                                      foreign_key: { to_table: :postnhost_article_snapshots, on_delete: :cascade }
      t.references :suggested_article, null: false, index: { name: "idx_postnhost_snapshot_suggestions_target" },
                                       foreign_key: { to_table: :postnhost_articles }
      t.integer :position, null: false
      t.timestamps null: false
    end

    add_index :postnhost_article_snapshot_suggestions, %i[article_snapshot_id suggested_article_id],
              unique: true, name: "idx_postnhost_snapshot_suggestions_unique"
    add_index :postnhost_article_snapshot_suggestions, %i[article_snapshot_id position],
              unique: true, name: "idx_postnhost_snapshot_suggestions_position"
    add_check_constraint :postnhost_article_snapshot_suggestions, "position >= 0",
                         name: "postnhost_snapshot_suggestion_position_nonnegative"

    create_table :postnhost_article_variant_snapshots do |t|
      t.references :article_variant, null: false,
                                     index: { unique: true, name: "idx_postnhost_article_variant_snapshots_variant" },
                                     foreign_key: { to_table: :postnhost_article_variants, on_delete: :cascade }
      t.references :article, null: false, foreign_key: { to_table: :postnhost_articles }
      t.references :paper_trail_version, null: false,
                                         index: { unique: true, name: "idx_postnhost_article_variant_snapshots_version" },
                                         foreign_key: { to_table: :postnhost_versions, on_delete: :restrict }
      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.string :title, null: false
      t.string :title_tag
      t.string :og_title
      t.string :schema_headline
      t.string :meta_description
      t.string :custom_excerpt
      t.string :auto_excerpt
      t.boolean :use_excerpt_as_meta_description, null: false, default: false
      t.text :content, null: false
      t.datetime :published_at, null: false
      t.timestamps null: false
    end

    add_index :postnhost_article_variant_snapshots, %i[article_id language_id], unique: true,
                                                                                name: "idx_postnhost_article_variant_snapshots_unique"
    add_index :postnhost_article_variant_snapshots, %i[language_id published_at],
              name: "idx_postnhost_article_variant_snapshots_language"

    create_table :postnhost_page_snapshots do |t|
      t.references :page, null: false, index: { unique: true },
                          foreign_key: { to_table: :postnhost_pages, on_delete: :cascade }
      t.references :paper_trail_version, null: false, index: { unique: true },
                                         foreign_key: { to_table: :postnhost_versions, on_delete: :restrict }
      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.string :title, null: false
      t.string :title_tag
      t.string :og_title
      t.string :meta_description
      t.text :content, null: false
      t.string :slug, null: false
      t.datetime :published_at, null: false
      t.timestamps null: false
    end

    add_index :postnhost_page_snapshots, :slug, unique: true
    add_index :postnhost_page_snapshots, %i[language_id published_at], name: "idx_postnhost_page_snapshots_language"

    create_table :postnhost_page_variant_snapshots do |t|
      t.references :page_variant, null: false,
                                  index: { unique: true, name: "idx_postnhost_page_variant_snapshots_variant" },
                                  foreign_key: { to_table: :postnhost_page_variants, on_delete: :cascade }
      t.references :page, null: false, foreign_key: { to_table: :postnhost_pages }
      t.references :paper_trail_version, null: false,
                                         index: { unique: true, name: "idx_postnhost_page_variant_snapshots_version" },
                                         foreign_key: { to_table: :postnhost_versions, on_delete: :restrict }
      t.references :language, null: false, foreign_key: { to_table: :postnhost_languages }
      t.string :title, null: false
      t.string :title_tag
      t.string :og_title
      t.string :meta_description
      t.text :content, null: false
      t.datetime :published_at, null: false
      t.timestamps null: false
    end

    add_index :postnhost_page_variant_snapshots, %i[page_id language_id], unique: true,
                                                                          name: "idx_postnhost_page_variant_snapshots_unique"
    add_index :postnhost_page_variant_snapshots, %i[language_id published_at],
              name: "idx_postnhost_page_variant_snapshots_language"

    create_table :postnhost_public_site_revisions do |t|
      t.bigint :revision, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps null: false
    end
  end
end
