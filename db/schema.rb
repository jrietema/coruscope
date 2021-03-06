# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140306171333) do

  create_table "cms_blocks", force: true do |t|
    t.integer  "page_id",                     null: false
    t.string   "identifier",                  null: false
    t.text     "content",    limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cms_blocks", ["page_id", "identifier"], name: "index_cms_blocks_on_page_id_and_identifier", using: :btree

  create_table "cms_categories", force: true do |t|
    t.integer "site_id",          null: false
    t.string  "label",            null: false
    t.string  "categorized_type", null: false
  end

  add_index "cms_categories", ["site_id", "categorized_type", "label"], name: "index_cms_categories_on_site_id_and_categorized_type_and_label", unique: true, using: :btree

  create_table "cms_categorizations", force: true do |t|
    t.integer "category_id",      null: false
    t.string  "categorized_type", null: false
    t.integer "categorized_id",   null: false
  end

  add_index "cms_categorizations", ["category_id", "categorized_type", "categorized_id"], name: "index_cms_categorizations_on_cat_id_and_catd_type_and_catd_id", unique: true, using: :btree

  create_table "cms_contact_forms", force: true do |t|
    t.integer "site_id",                                null: false
    t.string  "identifier",                             null: false
    t.string  "contact_fields",             limit: 600
    t.string  "addressee"
    t.string  "mailer_subject"
    t.string  "submit_label"
    t.string  "redirect_url",                           null: false
    t.text    "mailer_body"
    t.integer "contact_form_id"
    t.text    "contact_field_options"
    t.text    "contact_field_translations"
  end

  create_table "cms_contacts", force: true do |t|
    t.integer  "site_id"
    t.integer  "contact_form_id"
    t.datetime "created_at"
    t.string   "email"
    t.string   "contact_type"
    t.text     "contact_fields"
    t.text     "message_body"
  end

  create_table "cms_file_translations", force: true do |t|
    t.integer  "file_id",     null: false
    t.string   "locale",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "cms_file_translations", ["file_id"], name: "index_cms_file_translations_on_cms_file_id", using: :btree
  add_index "cms_file_translations", ["locale"], name: "index_cms_file_translations_on_locale", using: :btree

  create_table "cms_files", force: true do |t|
    t.integer  "site_id",                                    null: false
    t.integer  "block_id"
    t.string   "label",                                      null: false
    t.string   "file_file_name",                             null: false
    t.string   "file_content_type",                          null: false
    t.integer  "file_file_size",                             null: false
    t.string   "description",       limit: 2048
    t.integer  "position",                       default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  add_index "cms_files", ["site_id", "block_id"], name: "index_cms_files_on_site_id_and_block_id", using: :btree
  add_index "cms_files", ["site_id", "file_file_name"], name: "index_cms_files_on_site_id_and_file_file_name", using: :btree
  add_index "cms_files", ["site_id", "label"], name: "index_cms_files_on_site_id_and_label", using: :btree
  add_index "cms_files", ["site_id", "position"], name: "index_cms_files_on_site_id_and_position", using: :btree

  create_table "cms_groups", force: true do |t|
    t.string  "label",                                   null: false
    t.string  "grouped_type",                            null: false
    t.integer "site_id",                                 null: false
    t.integer "parent_id"
    t.integer "position",                    default: 0
    t.string  "description",    limit: 2048
    t.text    "presets"
    t.integer "children_count"
    t.string  "hierarchy_path"
  end

  create_table "cms_layouts", force: true do |t|
    t.integer  "site_id",                                     null: false
    t.integer  "parent_id"
    t.string   "app_layout"
    t.string   "label",                                       null: false
    t.string   "identifier",                                  null: false
    t.text     "content",    limit: 16777215
    t.text     "css",        limit: 16777215
    t.text     "js",         limit: 16777215
    t.integer  "position",                    default: 0,     null: false
    t.boolean  "is_shared",                   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cms_layouts", ["parent_id", "position"], name: "index_cms_layouts_on_parent_id_and_position", using: :btree
  add_index "cms_layouts", ["site_id", "identifier"], name: "index_cms_layouts_on_site_id_and_identifier", unique: true, using: :btree

  create_table "cms_pages", force: true do |t|
    t.integer  "site_id",                                             null: false
    t.integer  "layout_id"
    t.integer  "parent_id"
    t.integer  "target_page_id"
    t.string   "label",                                               null: false
    t.string   "slug"
    t.string   "full_path",                                           null: false
    t.text     "content",            limit: 16777215
    t.integer  "position",                            default: 0,     null: false
    t.integer  "children_count",                      default: 0,     null: false
    t.boolean  "is_published",                        default: true,  null: false
    t.boolean  "is_shared",                           default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "navigation_root_id"
    t.boolean  "render_as_page",                      default: true
    t.boolean  "is_leaf_node",                        default: false
    t.string   "identifier",                                          null: false
  end

  add_index "cms_pages", ["parent_id", "position"], name: "index_cms_pages_on_parent_id_and_position", using: :btree
  add_index "cms_pages", ["site_id", "full_path"], name: "index_cms_pages_on_site_id_and_full_path", using: :btree

  create_table "cms_revisions", force: true do |t|
    t.string   "record_type",                  null: false
    t.integer  "record_id",                    null: false
    t.text     "data",        limit: 16777215
    t.datetime "created_at"
  end

  add_index "cms_revisions", ["record_type", "record_id", "created_at"], name: "index_cms_revisions_on_rtype_and_rid_and_created_at", using: :btree

  create_table "cms_sites", force: true do |t|
    t.string   "label",                                                   null: false
    t.string   "identifier",                                              null: false
    t.string   "hostname",                                                null: false
    t.string   "path"
    t.string   "locale",                                  default: "en",  null: false
    t.boolean  "is_mirrored",                             default: false, null: false
    t.string   "contact_fields",              limit: 600
    t.text     "contact_field_translations"
    t.text     "contact_field_definitions"
    t.string   "default_addressee"
    t.boolean  "render_site_path",                        default: true
    t.string   "favicon_file_name"
    t.string   "favicon_content_type"
    t.integer  "favicon_file_size"
    t.datetime "favicon_updated_at"
    t.string   "identity_image_file_name"
    t.string   "identity_image_content_type"
    t.integer  "identity_image_file_size"
    t.datetime "identity_image_updated_at"
    t.text     "description"
    t.string   "keywords"
    t.text     "meta_tags"
  end

  add_index "cms_sites", ["hostname"], name: "index_cms_sites_on_hostname", using: :btree
  add_index "cms_sites", ["is_mirrored"], name: "index_cms_sites_on_is_mirrored", using: :btree

  create_table "cms_snippets", force: true do |t|
    t.integer  "site_id",                                     null: false
    t.string   "label",                                       null: false
    t.string   "identifier",                                  null: false
    t.text     "content",    limit: 16777215
    t.integer  "position",                    default: 0,     null: false
    t.boolean  "is_shared",                   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "group_id"
  end

  add_index "cms_snippets", ["site_id", "identifier"], name: "index_cms_snippets_on_site_id_and_identifier", unique: true, using: :btree
  add_index "cms_snippets", ["site_id", "position"], name: "index_cms_snippets_on_site_id_and_position", using: :btree

  create_table "users", force: true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
