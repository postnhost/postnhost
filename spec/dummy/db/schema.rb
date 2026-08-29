# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_26_130000) do
  create_table "host_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "postnhost_article_authors", force: :cascade do |t|
    t.integer "article_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["article_id", "position"], name: "index_postnhost_article_authors_on_article_id_and_position"
    t.index ["article_id", "user_id"], name: "index_postnhost_article_authors_on_article_id_and_user_id", unique: true
    t.index ["article_id"], name: "index_postnhost_article_authors_on_article_id"
    t.index ["user_id"], name: "index_postnhost_article_authors_on_user_id"
  end

  create_table "postnhost_article_categories", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "category_id"], name: "idx_on_article_id_category_id_ad0e456214", unique: true
    t.index ["article_id"], name: "index_postnhost_article_categories_on_article_id"
    t.index ["category_id"], name: "index_postnhost_article_categories_on_category_id"
  end

  create_table "postnhost_article_snapshot_authors", force: :cascade do |t|
    t.integer "article_snapshot_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["article_snapshot_id", "position"], name: "idx_postnhost_snapshot_authors_position", unique: true
    t.index ["article_snapshot_id", "user_id"], name: "idx_postnhost_snapshot_authors_unique", unique: true
    t.index ["article_snapshot_id"], name: "idx_postnhost_snapshot_authors_article"
    t.index ["user_id", "article_snapshot_id"], name: "idx_postnhost_snapshot_authors_reverse"
    t.index ["user_id"], name: "index_postnhost_article_snapshot_authors_on_user_id"
    t.check_constraint "position >= 0", name: "postnhost_snapshot_author_position_nonnegative"
  end

  create_table "postnhost_article_snapshot_categories", force: :cascade do |t|
    t.integer "article_snapshot_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_snapshot_id", "category_id"], name: "idx_postnhost_snapshot_categories_unique", unique: true
    t.index ["article_snapshot_id"], name: "idx_postnhost_snapshot_categories_article"
    t.index ["category_id", "article_snapshot_id"], name: "idx_postnhost_snapshot_categories_reverse"
    t.index ["category_id"], name: "index_postnhost_article_snapshot_categories_on_category_id"
  end

  create_table "postnhost_article_snapshot_suggestions", force: :cascade do |t|
    t.integer "article_snapshot_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "suggested_article_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_snapshot_id", "position"], name: "idx_postnhost_snapshot_suggestions_position", unique: true
    t.index ["article_snapshot_id", "suggested_article_id"], name: "idx_postnhost_snapshot_suggestions_unique", unique: true
    t.index ["article_snapshot_id"], name: "idx_postnhost_snapshot_suggestions_article"
    t.index ["suggested_article_id"], name: "idx_postnhost_snapshot_suggestions_target"
    t.check_constraint "position >= 0", name: "postnhost_snapshot_suggestion_position_nonnegative"
  end

  create_table "postnhost_article_snapshots", force: :cascade do |t|
    t.integer "article_id", null: false
    t.string "auto_excerpt"
    t.text "content", null: false
    t.string "cover_image_alt"
    t.string "cover_image_identifier"
    t.datetime "created_at", null: false
    t.string "custom_excerpt"
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.integer "paper_trail_version_id", null: false
    t.datetime "published_at", null: false
    t.string "schema_article_type"
    t.string "schema_headline"
    t.string "slug", null: false
    t.string "title", null: false
    t.string "title_tag"
    t.boolean "top_pick", default: false, null: false
    t.datetime "updated_at", null: false
    t.boolean "use_excerpt_as_meta_description", default: false, null: false
    t.index ["article_id"], name: "index_postnhost_article_snapshots_on_article_id", unique: true
    t.index ["language_id", "published_at"], name: "idx_postnhost_article_snapshots_language"
    t.index ["language_id"], name: "index_postnhost_article_snapshots_on_language_id"
    t.index ["paper_trail_version_id"], name: "index_postnhost_article_snapshots_on_paper_trail_version_id", unique: true
    t.index ["slug"], name: "index_postnhost_article_snapshots_on_slug", unique: true
    t.index ["top_pick", "language_id", "published_at"], name: "idx_postnhost_article_snapshots_top_picks"
    t.index ["updated_at"], name: "index_postnhost_article_snapshots_on_updated_at"
  end

  create_table "postnhost_article_suggestions", force: :cascade do |t|
    t.integer "article_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.integer "suggested_article_id", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "suggested_article_id"], name: "idx_on_article_id_suggested_article_id_becebf9686", unique: true
    t.index ["article_id"], name: "index_postnhost_article_suggestions_on_article_id"
    t.index ["suggested_article_id"], name: "index_postnhost_article_suggestions_on_suggested_article_id"
  end

  create_table "postnhost_article_variant_snapshots", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "article_variant_id", null: false
    t.string "auto_excerpt"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "custom_excerpt"
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.integer "paper_trail_version_id", null: false
    t.datetime "published_at", null: false
    t.string "schema_headline"
    t.string "title", null: false
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.boolean "use_excerpt_as_meta_description", default: false, null: false
    t.index ["article_id", "language_id"], name: "idx_postnhost_article_variant_snapshots_unique", unique: true
    t.index ["article_id"], name: "index_postnhost_article_variant_snapshots_on_article_id"
    t.index ["article_variant_id"], name: "idx_postnhost_article_variant_snapshots_variant", unique: true
    t.index ["language_id", "published_at"], name: "idx_postnhost_article_variant_snapshots_language"
    t.index ["language_id"], name: "index_postnhost_article_variant_snapshots_on_language_id"
    t.index ["paper_trail_version_id"], name: "idx_postnhost_article_variant_snapshots_version", unique: true
  end

  create_table "postnhost_article_variants", force: :cascade do |t|
    t.integer "article_id", null: false
    t.string "auto_excerpt"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "custom_excerpt"
    t.boolean "generating", default: false, null: false
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.string "schema_headline"
    t.string "title"
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.boolean "use_excerpt_as_meta_description", default: false, null: false
    t.index ["article_id", "language_id"], name: "index_postnhost_article_variants_on_article_id_and_language_id", unique: true
    t.index ["article_id"], name: "index_postnhost_article_variants_on_article_id"
    t.index ["language_id"], name: "index_postnhost_article_variants_on_language_id"
  end

  create_table "postnhost_articles", force: :cascade do |t|
    t.integer "article_variants_count", default: 0, null: false
    t.string "auto_excerpt"
    t.text "content"
    t.string "cover_image"
    t.string "cover_image_alt"
    t.datetime "created_at", null: false
    t.string "custom_excerpt"
    t.integer "language_id"
    t.string "meta_description"
    t.string "og_title"
    t.text "publication_error"
    t.datetime "scheduled_at"
    t.string "scheduled_job_id"
    t.string "schema_article_type"
    t.string "schema_headline"
    t.string "slug"
    t.string "title"
    t.string "title_tag"
    t.boolean "top_pick", default: false, null: false
    t.datetime "updated_at", null: false
    t.boolean "use_excerpt_as_meta_description", default: false, null: false
    t.integer "user_id"
    t.index ["language_id"], name: "index_postnhost_articles_on_language_id"
    t.index ["scheduled_at"], name: "index_postnhost_articles_on_scheduled_at"
    t.index ["scheduled_job_id"], name: "index_postnhost_articles_on_scheduled_job_id"
    t.index ["slug"], name: "index_postnhost_articles_on_slug", unique: true
    t.index ["top_pick"], name: "index_postnhost_articles_on_top_pick"
    t.index ["user_id"], name: "index_postnhost_articles_on_user_id"
  end

  create_table "postnhost_categories", force: :cascade do |t|
    t.integer "articles_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "meta_description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_postnhost_categories_on_name", unique: true
    t.index ["slug"], name: "index_postnhost_categories_on_slug", unique: true
  end

  create_table "postnhost_category_variants", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.boolean "generating", default: false, null: false
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["category_id", "language_id"], name: "idx_on_category_id_language_id_78b598242e", unique: true
    t.index ["category_id"], name: "index_postnhost_category_variants_on_category_id"
    t.index ["language_id"], name: "index_postnhost_category_variants_on_language_id"
  end

  create_table "postnhost_languages", force: :cascade do |t|
    t.integer "article_variants_count", default: 0, null: false
    t.integer "articles_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "html_lang"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["html_lang"], name: "index_postnhost_languages_on_html_lang", unique: true
    t.index ["name"], name: "index_postnhost_languages_on_name", unique: true
  end

  create_table "postnhost_navigation_items", force: :cascade do |t|
    t.integer "container_kind", null: false
    t.datetime "created_at", null: false
    t.integer "kind", null: false
    t.json "label_translations", default: {}, null: false
    t.integer "navigation_id", null: false
    t.boolean "nofollow", default: false, null: false
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.bigint "target_id"
    t.integer "target_kind"
    t.string "target_slug"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["navigation_id", "container_kind", "position"], name: "idx_postnhost_navigation_items_on_nav_container_position"
    t.index ["navigation_id"], name: "index_postnhost_navigation_items_on_navigation_id"
    t.index ["parent_id", "position"], name: "idx_postnhost_navigation_items_on_parent_position"
    t.index ["parent_id"], name: "index_postnhost_navigation_items_on_parent_id"
  end

  create_table "postnhost_navigations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "setting_id", null: false
    t.datetime "updated_at", null: false
    t.index ["setting_id"], name: "index_postnhost_navigations_on_setting_id", unique: true
  end

  create_table "postnhost_page_snapshots", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.integer "page_id", null: false
    t.integer "paper_trail_version_id", null: false
    t.datetime "published_at", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.index ["language_id", "published_at"], name: "idx_postnhost_page_snapshots_language"
    t.index ["language_id"], name: "index_postnhost_page_snapshots_on_language_id"
    t.index ["page_id"], name: "index_postnhost_page_snapshots_on_page_id", unique: true
    t.index ["paper_trail_version_id"], name: "index_postnhost_page_snapshots_on_paper_trail_version_id", unique: true
    t.index ["slug"], name: "index_postnhost_page_snapshots_on_slug", unique: true
  end

  create_table "postnhost_page_variant_snapshots", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.integer "page_id", null: false
    t.integer "page_variant_id", null: false
    t.integer "paper_trail_version_id", null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.index ["language_id", "published_at"], name: "idx_postnhost_page_variant_snapshots_language"
    t.index ["language_id"], name: "index_postnhost_page_variant_snapshots_on_language_id"
    t.index ["page_id", "language_id"], name: "idx_postnhost_page_variant_snapshots_unique", unique: true
    t.index ["page_id"], name: "index_postnhost_page_variant_snapshots_on_page_id"
    t.index ["page_variant_id"], name: "idx_postnhost_page_variant_snapshots_variant", unique: true
    t.index ["paper_trail_version_id"], name: "idx_postnhost_page_variant_snapshots_version", unique: true
  end

  create_table "postnhost_page_variants", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "generating", default: false, null: false
    t.integer "language_id", null: false
    t.string "meta_description"
    t.string "og_title"
    t.integer "page_id", null: false
    t.string "title"
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.index ["language_id"], name: "index_postnhost_page_variants_on_language_id"
    t.index ["page_id", "language_id"], name: "index_postnhost_page_variants_on_page_id_and_language_id", unique: true
    t.index ["page_id"], name: "index_postnhost_page_variants_on_page_id"
  end

  create_table "postnhost_pages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "language_id"
    t.string "meta_description"
    t.string "og_title"
    t.integer "page_variants_count", default: 0, null: false
    t.string "slug"
    t.string "title"
    t.string "title_tag"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["language_id"], name: "index_postnhost_pages_on_language_id"
    t.index ["slug"], name: "index_postnhost_pages_on_slug", unique: true
    t.index ["user_id"], name: "index_postnhost_pages_on_user_id"
  end

  create_table "postnhost_public_site_revisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "revision", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "postnhost_settings", force: :cascade do |t|
    t.boolean "author_pages_enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.json "locale_overrides", default: {}, null: false
    t.integer "lock_version", default: 0, null: false
    t.string "og_image"
    t.integer "public_page_size"
    t.json "schema_locale_overrides", default: {}, null: false
    t.json "schema_settings", default: {}, null: false
    t.boolean "search_enabled", default: true, null: false
    t.boolean "show_powered_by", default: true, null: false
    t.string "site_indexing", default: "index", null: false
    t.string "site_logo"
    t.string "site_url"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.boolean "use_auto_footer_navigation", default: true, null: false
    t.boolean "use_auto_header_navigation", default: true, null: false
  end

  create_table "postnhost_site_scripts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "placement", null: false
    t.text "script"
    t.integer "setting_id", null: false
    t.datetime "updated_at", null: false
    t.index ["setting_id"], name: "index_postnhost_site_scripts_on_setting_id"
  end

  create_table "postnhost_templates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", default: "default", null: false
    t.datetime "updated_at", null: false
  end

  create_table "postnhost_users", force: :cascade do |t|
    t.string "avatar_file"
    t.text "bio"
    t.string "bluesky_url"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "facebook_url"
    t.string "instagram_url"
    t.string "linkedin_url"
    t.string "mastodon_url"
    t.string "name"
    t.string "password_digest", null: false
    t.string "position"
    t.json "schema_locale_overrides", default: {}, null: false
    t.json "schema_profile", default: {}, null: false
    t.string "slug", null: false
    t.string "threads_url"
    t.string "tiktok_url"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "x_url"
    t.string "youtube_url"
    t.index ["email"], name: "index_postnhost_users_on_email", unique: true
    t.index ["slug"], name: "index_postnhost_users_on_slug", unique: true
  end

  create_table "postnhost_versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object", limit: 1073741823
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_postnhost_versions_on_item_type_and_item_id"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object", limit: 1073741823
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "postnhost_article_authors", "postnhost_articles", column: "article_id"
  add_foreign_key "postnhost_article_authors", "postnhost_users", column: "user_id"
  add_foreign_key "postnhost_article_categories", "postnhost_articles", column: "article_id"
  add_foreign_key "postnhost_article_categories", "postnhost_categories", column: "category_id"
  add_foreign_key "postnhost_article_snapshot_authors", "postnhost_article_snapshots", column: "article_snapshot_id", on_delete: :cascade
  add_foreign_key "postnhost_article_snapshot_authors", "postnhost_users", column: "user_id"
  add_foreign_key "postnhost_article_snapshot_categories", "postnhost_article_snapshots", column: "article_snapshot_id", on_delete: :cascade
  add_foreign_key "postnhost_article_snapshot_categories", "postnhost_categories", column: "category_id"
  add_foreign_key "postnhost_article_snapshot_suggestions", "postnhost_article_snapshots", column: "article_snapshot_id", on_delete: :cascade
  add_foreign_key "postnhost_article_snapshot_suggestions", "postnhost_articles", column: "suggested_article_id"
  add_foreign_key "postnhost_article_snapshots", "postnhost_articles", column: "article_id", on_delete: :cascade
  add_foreign_key "postnhost_article_snapshots", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_article_snapshots", "postnhost_versions", column: "paper_trail_version_id", on_delete: :restrict
  add_foreign_key "postnhost_article_suggestions", "postnhost_articles", column: "article_id"
  add_foreign_key "postnhost_article_suggestions", "postnhost_articles", column: "suggested_article_id"
  add_foreign_key "postnhost_article_variant_snapshots", "postnhost_article_variants", column: "article_variant_id", on_delete: :cascade
  add_foreign_key "postnhost_article_variant_snapshots", "postnhost_articles", column: "article_id"
  add_foreign_key "postnhost_article_variant_snapshots", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_article_variant_snapshots", "postnhost_versions", column: "paper_trail_version_id", on_delete: :restrict
  add_foreign_key "postnhost_article_variants", "postnhost_articles", column: "article_id"
  add_foreign_key "postnhost_article_variants", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_articles", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_category_variants", "postnhost_categories", column: "category_id"
  add_foreign_key "postnhost_category_variants", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_navigation_items", "postnhost_navigation_items", column: "parent_id"
  add_foreign_key "postnhost_navigation_items", "postnhost_navigations", column: "navigation_id"
  add_foreign_key "postnhost_navigations", "postnhost_settings", column: "setting_id"
  add_foreign_key "postnhost_page_snapshots", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_page_snapshots", "postnhost_pages", column: "page_id", on_delete: :cascade
  add_foreign_key "postnhost_page_snapshots", "postnhost_versions", column: "paper_trail_version_id", on_delete: :restrict
  add_foreign_key "postnhost_page_variant_snapshots", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_page_variant_snapshots", "postnhost_page_variants", column: "page_variant_id", on_delete: :cascade
  add_foreign_key "postnhost_page_variant_snapshots", "postnhost_pages", column: "page_id"
  add_foreign_key "postnhost_page_variant_snapshots", "postnhost_versions", column: "paper_trail_version_id", on_delete: :restrict
  add_foreign_key "postnhost_page_variants", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_page_variants", "postnhost_pages", column: "page_id"
  add_foreign_key "postnhost_pages", "postnhost_languages", column: "language_id"
  add_foreign_key "postnhost_pages", "postnhost_users", column: "user_id"
  add_foreign_key "postnhost_site_scripts", "postnhost_settings", column: "setting_id"
end
