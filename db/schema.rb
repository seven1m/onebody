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

ActiveRecord::Schema.define(version: 20161027001942) do

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",       limit: 4
    t.string   "template_name", limit: 100
    t.text     "flags",         limit: 65535
    t.boolean  "super_admin",                 default: false
  end

  add_index "admins", ["site_id"], name: "index_site_id_on_admins", using: :btree

  create_table "admins_reports", id: false, force: :cascade do |t|
    t.integer "admin_id",  limit: 4
    t.integer "report_id", limit: 4
  end

  create_table "albums", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.integer  "site_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_public",                 default: false
    t.integer  "owner_id",    limit: 4
    t.string   "owner_type",  limit: 255
  end

  create_table "attachments", force: :cascade do |t|
    t.integer  "message_id",        limit: 4
    t.string   "name",              limit: 255
    t.string   "content_type",      limit: 255
    t.datetime "created_at"
    t.integer  "site_id",           limit: 4
    t.integer  "page_id",           limit: 4
    t.integer  "group_id",          limit: 4
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.string   "file_fingerprint",  limit: 50
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.integer  "site_id",             limit: 4
    t.integer  "person_id",           limit: 4
    t.integer  "group_id",            limit: 4
    t.datetime "attended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name",          limit: 255
    t.string   "last_name",           limit: 255
    t.string   "family_name",         limit: 255
    t.string   "age",                 limit: 255
    t.string   "can_pick_up",         limit: 100
    t.string   "cannot_pick_up",      limit: 100
    t.string   "medical_notes",       limit: 200
    t.integer  "checkin_time_id",     limit: 4
    t.boolean  "print_extra_nametag"
    t.string   "barcode_id",          limit: 50
    t.integer  "label_id",            limit: 4
  end

  add_index "attendance_records", ["attended_at"], name: "index_attended_at_on_attendance_records", using: :btree
  add_index "attendance_records", ["group_id"], name: "index_group_id_on_attendance_records", using: :btree
  add_index "attendance_records", ["person_id"], name: "index_person_id_on_attendance_records", using: :btree
  add_index "attendance_records", ["site_id"], name: "index_site_id_on_attendance_records", using: :btree

  create_table "checkin_folders", force: :cascade do |t|
    t.integer "site_id",         limit: 4
    t.integer "checkin_time_id", limit: 4
    t.string  "name",            limit: 255
    t.integer "sequence",        limit: 4
    t.boolean "active",                      default: true
  end

  create_table "checkin_labels", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 1000
    t.text     "xml",         limit: 65535
    t.integer  "site_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "checkin_times", force: :cascade do |t|
    t.integer  "weekday",      limit: 4
    t.integer  "time",         limit: 4
    t.datetime "the_datetime"
    t.integer  "site_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "campus",       limit: 255
  end

  create_table "chms_syncs", force: :cascade do |t|
    t.integer  "site_id",              limit: 4
    t.integer  "person_id",            limit: 4
    t.datetime "last_started"
    t.datetime "last_completed"
    t.string   "remote_url",           limit: 255
    t.string   "remote_user",          limit: 255
    t.string   "remote_password_hash", limit: 255
    t.string   "chms_name",            limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "verse_id",         limit: 4
    t.integer  "person_id",        limit: 4
    t.text     "text",             limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recipe_id",        limit: 4
    t.integer  "news_item_id",     limit: 4
    t.integer  "song_id",          limit: 4
    t.integer  "site_id",          limit: 4
    t.integer  "picture_id",       limit: 4
    t.integer  "commentable_id",   limit: 4
    t.string   "commentable_type", limit: 255
  end

  create_table "custom_field_values", force: :cascade do |t|
    t.integer "site_id",     limit: 4
    t.integer "field_id",    limit: 4
    t.integer "object_id",   limit: 4
    t.string  "object_type", limit: 255
    t.string  "value",       limit: 255
  end

  create_table "custom_fields", force: :cascade do |t|
    t.integer  "site_id",    limit: 4
    t.string   "name",       limit: 50
    t.string   "format",     limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_reports", force: :cascade do |t|
    t.integer "site_id",  limit: 4
    t.string  "title",    limit: 255
    t.string  "category", limit: 255
    t.text    "header",   limit: 65535
    t.text    "body",     limit: 65535
    t.text    "footer",   limit: 65535
    t.string  "filters",  limit: 255
  end

  create_table "document_folder_groups", force: :cascade do |t|
    t.integer  "document_folder_id", limit: 4
    t.integer  "group_id",           limit: 4
    t.datetime "created_at"
    t.integer  "site_id",            limit: 4
  end

  add_index "document_folder_groups", ["document_folder_id"], name: "index_document_folder_groups_on_document_folder_id", using: :btree
  add_index "document_folder_groups", ["group_id"], name: "index_document_folder_groups_on_group_id", using: :btree

  create_table "document_folders", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "description",       limit: 1000
    t.boolean  "hidden",                         default: false
    t.integer  "folder_id",         limit: 4
    t.string   "parent_folder_ids", limit: 1000
    t.string   "path",              limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",           limit: 4
  end

  create_table "documents", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "description",          limit: 1000
    t.integer  "folder_id",            limit: 4
    t.string   "file_file_name",       limit: 255
    t.string   "file_content_type",    limit: 255
    t.string   "file_fingerprint",     limit: 50
    t.integer  "file_file_size",       limit: 4
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",              limit: 4
    t.string   "preview_file_name",    limit: 255
    t.string   "preview_content_type", limit: 255
    t.string   "preview_fingerprint",  limit: 50
    t.integer  "preview_file_size",    limit: 4
    t.datetime "preview_updated_at"
  end

  create_table "families", force: :cascade do |t|
    t.integer  "legacy_id",            limit: 4
    t.string   "name",                 limit: 255
    t.string   "last_name",            limit: 255
    t.string   "suffix",               limit: 25
    t.string   "address1",             limit: 255
    t.string   "address2",             limit: 255
    t.string   "city",                 limit: 255
    t.string   "state",                limit: 255
    t.string   "zip",                  limit: 10
    t.string   "home_phone",           limit: 25
    t.string   "email",                limit: 255
    t.float    "latitude",             limit: 24
    t.float    "longitude",            limit: 24
    t.datetime "updated_at"
    t.boolean  "visible",                          default: true
    t.integer  "site_id",              limit: 4
    t.boolean  "deleted",                          default: false, null: false
    t.string   "barcode_id",           limit: 50
    t.datetime "barcode_assigned_at"
    t.boolean  "barcode_id_changed",               default: false
    t.string   "alternate_barcode_id", limit: 50
    t.string   "photo_file_name",      limit: 255
    t.string   "photo_content_type",   limit: 255
    t.string   "photo_fingerprint",    limit: 50
    t.integer  "photo_file_size",      limit: 4
    t.datetime "photo_updated_at"
    t.string   "country",              limit: 2
  end

  add_index "families", ["last_name", "name"], name: "index_family_names", using: :btree
  add_index "families", ["legacy_id"], name: "index_families_on_legacy_id", using: :btree

  create_table "friendship_requests", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.integer  "from_id",    limit: 4
    t.boolean  "rejected",             default: false
    t.datetime "created_at"
    t.integer  "site_id",    limit: 4
  end

  add_index "friendship_requests", ["person_id"], name: "index_friendship_requests_on_person_id", using: :btree

  create_table "friendships", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.integer  "friend_id",  limit: 4
    t.datetime "created_at"
    t.integer  "ordering",   limit: 4, default: 1000
    t.integer  "site_id",    limit: 4
  end

  add_index "friendships", ["friend_id"], name: "index_friendships_on_friend_id", using: :btree
  add_index "friendships", ["person_id"], name: "index_friendships_on_person_id", using: :btree

  create_table "generated_files", force: :cascade do |t|
    t.integer  "site_id",           limit: 4
    t.integer  "person_id",         limit: 4
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.string   "file_fingerprint",  limit: 50
    t.integer  "file_file_size",    limit: 4
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "job_id",            limit: 50
  end

  create_table "group_times", force: :cascade do |t|
    t.integer  "group_id",            limit: 4
    t.integer  "checkin_time_id",     limit: 4
    t.integer  "sequence",            limit: 4
    t.integer  "site_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "section",             limit: 100
    t.boolean  "print_extra_nametag",             default: false
    t.integer  "checkin_folder_id",   limit: 4
    t.integer  "label_id",            limit: 4
  end

  create_table "groups", force: :cascade do |t|
    t.string   "name",                      limit: 100
    t.text     "description",               limit: 65535
    t.string   "meets",                     limit: 100
    t.string   "location",                  limit: 100
    t.text     "directions",                limit: 65535
    t.text     "other_notes",               limit: 65535
    t.string   "category",                  limit: 50
    t.integer  "creator_id",                limit: 4
    t.boolean  "private",                                 default: false
    t.string   "address",                   limit: 255
    t.boolean  "members_send",                            default: true
    t.integer  "leader_id",                 limit: 4
    t.datetime "updated_at"
    t.boolean  "hidden",                                  default: false
    t.boolean  "approved",                                default: false
    t.string   "link_code",                 limit: 255
    t.integer  "parents_of",                limit: 4
    t.integer  "site_id",                   limit: 4
    t.boolean  "blog",                                    default: true
    t.boolean  "email",                                   default: true
    t.boolean  "prayer",                                  default: true
    t.boolean  "attendance",                              default: true
    t.integer  "legacy_id",                 limit: 4
    t.string   "gcal_private_link",         limit: 255
    t.boolean  "approval_required_to_join",               default: true
    t.boolean  "pictures",                                default: true
    t.string   "cm_api_list_id",            limit: 50
    t.string   "photo_file_name",           limit: 255
    t.string   "photo_content_type",        limit: 255
    t.string   "photo_fingerprint",         limit: 50
    t.integer  "photo_file_size",           limit: 4
    t.datetime "photo_updated_at"
    t.datetime "created_at"
    t.float    "latitude",                  limit: 24
    t.float    "longitude",                 limit: 24
    t.string   "membership_mode",           limit: 10,    default: "manual"
    t.boolean  "has_tasks",                               default: false
    t.string   "share_token",               limit: 50
  end

  add_index "groups", ["category"], name: "index_groups_on_category", using: :btree
  add_index "groups", ["site_id"], name: "index_site_id_on_groups", using: :btree

  create_table "import_rows", force: :cascade do |t|
    t.integer "site_id",           limit: 4
    t.integer "import_id",         limit: 4
    t.integer "sequence",          limit: 4,                     null: false
    t.integer "person_id",         limit: 4
    t.boolean "created_person",                  default: false
    t.boolean "created_family",                  default: false
    t.boolean "updated_person",                  default: false
    t.boolean "updated_family",                  default: false
    t.integer "family_id",         limit: 4
    t.integer "matched_person_by", limit: 4
    t.integer "matched_family_by", limit: 4
    t.integer "status",            limit: 4
    t.text    "import_attributes", limit: 65535
    t.text    "attribute_changes", limit: 65535
    t.text    "attribute_errors",  limit: 65535
    t.boolean "errored",                         default: false
  end

  add_index "import_rows", ["site_id", "import_id"], name: "index_import_rows_on_site_id_and_import_id", using: :btree

  create_table "imports", force: :cascade do |t|
    t.integer  "site_id",         limit: 4
    t.integer  "person_id",       limit: 4
    t.string   "filename",        limit: 255,               null: false
    t.integer  "status",          limit: 4,                 null: false
    t.string   "error_message",   limit: 255
    t.string   "importable_type", limit: 50,                null: false
    t.text     "mappings",        limit: 65535
    t.integer  "match_strategy",  limit: 4
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.datetime "completed_at"
    t.integer  "row_count",       limit: 4,     default: 0
    t.integer  "flags",           limit: 4,     default: 0, null: false
  end

  create_table "jobs", force: :cascade do |t|
    t.integer  "site_id",    limit: 4
    t.string   "command",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "membership_requests", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.integer  "group_id",   limit: 4
    t.datetime "created_at"
    t.integer  "site_id",    limit: 4
  end

  create_table "memberships", force: :cascade do |t|
    t.integer  "group_id",           limit: 4
    t.integer  "person_id",          limit: 4
    t.boolean  "admin",                            default: false
    t.boolean  "get_email",                        default: true
    t.boolean  "share_address",                    default: false
    t.boolean  "share_mobile_phone",               default: false
    t.boolean  "share_work_phone",                 default: false
    t.boolean  "share_fax",                        default: false
    t.boolean  "share_email",                      default: false
    t.boolean  "share_birthday",                   default: false
    t.boolean  "share_anniversary",                default: false
    t.datetime "updated_at"
    t.integer  "code",               limit: 4
    t.integer  "site_id",            limit: 4
    t.integer  "legacy_id",          limit: 4
    t.boolean  "share_home_phone",                 default: false
    t.boolean  "auto",                             default: false
    t.datetime "created_at"
    t.text     "roles",              limit: 65535
  end

  add_index "memberships", ["group_id"], name: "index_memberships_on_group_id", using: :btree
  add_index "memberships", ["person_id"], name: "index_memberships_on_person_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "group_id",     limit: 4
    t.integer  "person_id",    limit: 4
    t.integer  "to_person_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id",    limit: 4
    t.string   "subject",      limit: 255
    t.text     "body",         limit: 65535
    t.boolean  "share_email",                default: false
    t.integer  "code",         limit: 4
    t.integer  "site_id",      limit: 4
    t.text     "html_body",    limit: 65535
  end

  add_index "messages", ["created_at"], name: "index_messages_on_created_at", using: :btree

  create_table "news_items", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "link",       limit: 255
    t.text     "body",       limit: 65535
    t.datetime "published"
    t.boolean  "active",                   default: true
    t.integer  "site_id",    limit: 4
    t.string   "source",     limit: 255
    t.integer  "person_id",  limit: 4
    t.integer  "sequence",   limit: 4
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4,     null: false
    t.integer  "application_id",    limit: 4,     null: false
    t.string   "token",             limit: 255,   null: false
    t.integer  "expires_in",        limit: 4,     null: false
    t.text     "redirect_uri",      limit: 65535, null: false
    t.datetime "created_at",                      null: false
    t.datetime "revoked_at"
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", limit: 4
    t.integer  "application_id",    limit: 4
    t.string   "token",             limit: 255, null: false
    t.string   "refresh_token",     limit: 255
    t.integer  "expires_in",        limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at",                    null: false
    t.string   "scopes",            limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         limit: 255,                null: false
    t.string   "uid",          limit: 255,                null: false
    t.string   "secret",       limit: 255,                null: false
    t.text     "redirect_uri", limit: 65535,              null: false
    t.string   "scopes",       limit: 255,   default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "pages", force: :cascade do |t|
    t.string   "slug",       limit: 255
    t.string   "title",      limit: 255
    t.text     "body",       limit: 65535
    t.integer  "parent_id",  limit: 4
    t.string   "path",       limit: 255
    t.boolean  "published",                default: true
    t.integer  "site_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "navigation",               default: true
    t.boolean  "system",                   default: false
    t.boolean  "raw",                      default: false
  end

  add_index "pages", ["parent_id"], name: "index_pages_on_parent_id", using: :btree
  add_index "pages", ["path"], name: "index_pages_on_path", using: :btree

  create_table "people", force: :cascade do |t|
    t.integer  "legacy_id",                limit: 4
    t.integer  "family_id",                limit: 4
    t.integer  "position",                 limit: 4
    t.string   "gender",                   limit: 6
    t.string   "first_name",               limit: 255
    t.string   "last_name",                limit: 255
    t.string   "suffix",                   limit: 25
    t.string   "mobile_phone",             limit: 25
    t.string   "work_phone",               limit: 25
    t.string   "fax",                      limit: 25
    t.datetime "birthday"
    t.string   "email",                    limit: 255
    t.boolean  "email_changed",                          default: false
    t.string   "website",                  limit: 255
    t.text     "classes",                  limit: 65535
    t.string   "shepherd",                 limit: 255
    t.string   "mail_group",               limit: 1
    t.string   "encrypted_password",       limit: 100
    t.string   "business_name",            limit: 100
    t.text     "business_description",     limit: 65535
    t.string   "business_phone",           limit: 25
    t.string   "business_email",           limit: 255
    t.string   "business_website",         limit: 255
    t.text     "about",                    limit: 65535
    t.text     "testimony",                limit: 65535
    t.boolean  "share_mobile_phone",                     default: false
    t.boolean  "share_work_phone",                       default: false
    t.boolean  "share_fax",                              default: false
    t.boolean  "share_email",                            default: false
    t.boolean  "share_birthday",                         default: true
    t.datetime "anniversary"
    t.datetime "updated_at"
    t.string   "alternate_email",          limit: 255
    t.integer  "email_bounces",            limit: 4,     default: 0
    t.string   "business_category",        limit: 100
    t.boolean  "account_frozen",                         default: false
    t.boolean  "messages_enabled",                       default: true
    t.string   "business_address",         limit: 255
    t.string   "flags",                    limit: 255
    t.boolean  "visible",                                default: true
    t.string   "parental_consent",         limit: 255
    t.integer  "admin_id",                 limit: 4
    t.boolean  "friends_enabled",                        default: true
    t.boolean  "member",                                 default: false
    t.boolean  "staff",                                  default: false
    t.boolean  "elder",                                  default: false
    t.boolean  "deacon",                                 default: false
    t.integer  "legacy_family_id",         limit: 4
    t.string   "feed_code",                limit: 50
    t.boolean  "share_activity",                         default: true
    t.integer  "site_id",                  limit: 4
    t.string   "twitter_account",          limit: 100
    t.string   "api_key",                  limit: 50
    t.string   "salt",                     limit: 50
    t.boolean  "deleted",                                default: false, null: false
    t.boolean  "child"
    t.string   "custom_type",              limit: 100
    t.text     "custom_fields",            limit: 65535
    t.string   "can_pick_up",              limit: 100
    t.string   "cannot_pick_up",           limit: 100
    t.string   "medical_notes",            limit: 200
    t.string   "relationships_hash",       limit: 40
    t.string   "photo_file_name",          limit: 255
    t.string   "photo_content_type",       limit: 255
    t.string   "photo_fingerprint",        limit: 50
    t.integer  "photo_file_size",          limit: 4
    t.datetime "photo_updated_at"
    t.string   "description",              limit: 25
    t.boolean  "share_anniversary",                      default: true
    t.boolean  "share_address",                          default: true
    t.boolean  "share_home_phone",                       default: true
    t.string   "password_hash",            limit: 255
    t.string   "password_salt",            limit: 255
    t.datetime "created_at"
    t.string   "facebook_url",             limit: 255
    t.string   "twitter",                  limit: 15
    t.integer  "incomplete_tasks_count",   limit: 4,     default: 0
    t.boolean  "primary_emailer"
    t.integer  "last_seen_stream_item_id", limit: 4
    t.integer  "last_seen_group_id",       limit: 4
    t.string   "provider",                 limit: 255
    t.string   "uid",                      limit: 255
    t.integer  "status",                   limit: 4
    t.string   "alias",                    limit: 255
  end

  add_index "people", ["admin_id"], name: "index_admin_id_on_people", using: :btree
  add_index "people", ["business_category"], name: "index_business_category_on_people", using: :btree
  add_index "people", ["email"], name: "index_people_on_email", using: :btree
  add_index "people", ["family_id"], name: "index_people_on_family_id", using: :btree
  add_index "people", ["legacy_id"], name: "index_people_on_legacy_id", using: :btree
  add_index "people", ["site_id", "feed_code"], name: "index_people_on_site_id_and_feed_code", using: :btree
  add_index "people", ["site_id"], name: "index_site_id_on_people", using: :btree

  create_table "people_verses", id: false, force: :cascade do |t|
    t.integer "person_id", limit: 4
    t.integer "verse_id",  limit: 4
  end

  create_table "pictures", force: :cascade do |t|
    t.integer  "person_id",          limit: 4
    t.datetime "created_at"
    t.boolean  "cover",                           default: false
    t.datetime "updated_at"
    t.integer  "site_id",            limit: 4
    t.integer  "album_id",           limit: 4
    t.string   "original_url",       limit: 1000
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.string   "photo_fingerprint",  limit: 50
    t.integer  "photo_file_size",    limit: 4
    t.datetime "photo_updated_at"
  end

  add_index "pictures", ["album_id"], name: "index_pictures_on_album_id", using: :btree

  create_table "prayer_requests", force: :cascade do |t|
    t.integer  "group_id",    limit: 4
    t.integer  "person_id",   limit: 4
    t.text     "request",     limit: 65535
    t.text     "answer",      limit: 65535
    t.datetime "answered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",     limit: 4
  end

  create_table "prayer_signups", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.datetime "start"
    t.datetime "created_at"
    t.boolean  "reminded",               default: false
    t.string   "other_name", limit: 100
    t.integer  "site_id",    limit: 4
  end

  create_table "processed_messages", force: :cascade do |t|
    t.string   "header_message_id", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipes", force: :cascade do |t|
    t.integer  "person_id",          limit: 4
    t.string   "title",              limit: 255
    t.text     "notes",              limit: 65535
    t.text     "description",        limit: 65535
    t.text     "ingredients",        limit: 65535
    t.text     "directions",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prep",               limit: 255
    t.string   "bake",               limit: 255
    t.integer  "serving_size",       limit: 4
    t.integer  "site_id",            limit: 4
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.string   "photo_fingerprint",  limit: 50
    t.integer  "photo_file_size",    limit: 4
    t.datetime "photo_updated_at"
  end

  create_table "relationships", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.integer  "related_id", limit: 4
    t.string   "name",       limit: 255
    t.string   "other_name", limit: 255
    t.integer  "site_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: :cascade do |t|
    t.integer  "site_id",        limit: 4
    t.string   "name",           limit: 255
    t.text     "definition",     limit: 65535
    t.boolean  "restricted",                   default: true
    t.integer  "created_by_id",  limit: 4
    t.integer  "run_count",      limit: 4,     default: 0
    t.datetime "last_run_at"
    t.integer  "last_run_by_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_categories", force: :cascade do |t|
    t.string  "name",        limit: 255,   null: false
    t.text    "description", limit: 65535
    t.integer "site_id",     limit: 4
  end

  create_table "services", force: :cascade do |t|
    t.integer  "person_id",           limit: 4,                       null: false
    t.integer  "service_category_id", limit: 4,                       null: false
    t.string   "status",              limit: 255, default: "current", null: false
    t.integer  "site_id",             limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255
    t.text     "data",       limit: 65535
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "section",     limit: 100
    t.string   "name",        limit: 100
    t.string   "format",      limit: 20
    t.string   "value",       limit: 500
    t.string   "description", limit: 500
    t.boolean  "hidden",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",     limit: 4
    t.boolean  "global",                  default: false
  end

  create_table "signin_failures", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.string   "ip",         limit: 255
    t.datetime "created_at"
  end

  create_table "sites", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.string   "host",                  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "secondary_host",        limit: 255
    t.integer  "max_admins",            limit: 4
    t.integer  "max_people",            limit: 4
    t.integer  "max_groups",            limit: 4
    t.boolean  "import_export_enabled",             default: true
    t.boolean  "pages_enabled",                     default: true
    t.boolean  "pictures_enabled",                  default: true
    t.boolean  "publications_enabled",              default: true
    t.boolean  "active",                            default: true
    t.boolean  "twitter_enabled",                   default: false
    t.string   "external_guid",         limit: 255, default: "0"
    t.datetime "settings_changed_at"
    t.string   "logo_file_name",        limit: 255
    t.string   "logo_content_type",     limit: 255
    t.string   "logo_fingerprint",      limit: 50
    t.integer  "logo_file_size",        limit: 4
    t.datetime "logo_updated_at"
    t.string   "email_host",            limit: 255
  end

  add_index "sites", ["host"], name: "index_sites_on_host", using: :btree

  create_table "stream_items", force: :cascade do |t|
    t.integer  "site_id",              limit: 4
    t.string   "title",                limit: 500
    t.text     "body",                 limit: 65535
    t.text     "context",              limit: 65535
    t.integer  "person_id",            limit: 4
    t.integer  "group_id",             limit: 4
    t.integer  "streamable_id",        limit: 4
    t.string   "streamable_type",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "shared"
    t.boolean  "text",                               default: false
    t.boolean  "is_public"
    t.integer  "stream_item_group_id", limit: 4
  end

  add_index "stream_items", ["created_at"], name: "index_stream_items_on_created_at", using: :btree
  add_index "stream_items", ["group_id"], name: "index_stream_items_on_group_id", using: :btree
  add_index "stream_items", ["person_id"], name: "index_stream_items_on_person_id", using: :btree
  add_index "stream_items", ["streamable_type", "streamable_id"], name: "index_stream_items_on_streamable_type_and_streamable_id", using: :btree

  create_table "sync_items", force: :cascade do |t|
    t.integer "site_id",        limit: 4
    t.integer "sync_id",        limit: 4
    t.integer "syncable_id",    limit: 4
    t.string  "syncable_type",  limit: 255
    t.integer "legacy_id",      limit: 4
    t.string  "name",           limit: 255
    t.string  "operation",      limit: 50
    t.string  "status",         limit: 50
    t.text    "error_messages", limit: 65535
  end

  add_index "sync_items", ["sync_id"], name: "index_sync_id_on_sync_items", using: :btree
  add_index "sync_items", ["syncable_type", "syncable_id"], name: "index_syncable_on_sync_items", using: :btree

  create_table "syncs", force: :cascade do |t|
    t.integer  "site_id",       limit: 4
    t.integer  "person_id",     limit: 4
    t.boolean  "complete",                default: false
    t.integer  "success_count", limit: 4
    t.integer  "error_count",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "finished_at"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string   "name",       limit: 50
    t.datetime "updated_at"
    t.integer  "site_id",    limit: 4
  end

  create_table "tasks", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.boolean  "completed",                 default: false
    t.date     "duedate"
    t.integer  "group_id",    limit: 4
    t.integer  "person_id",   limit: 4
    t.integer  "site_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",    limit: 4
    t.boolean  "group_scope"
  end

  create_table "twitter_messages", force: :cascade do |t|
    t.integer  "twitter_screen_name", limit: 4
    t.integer  "person_id",           limit: 4
    t.string   "message",             limit: 140
    t.string   "reply",               limit: 140
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",             limit: 4
    t.string   "twitter_message_id",  limit: 255
  end

  create_table "updates", force: :cascade do |t|
    t.integer  "person_id",  limit: 4
    t.datetime "created_at"
    t.boolean  "complete",                 default: false
    t.integer  "site_id",    limit: 4
    t.text     "data",       limit: 65535
    t.text     "diff",       limit: 65535
    t.integer  "family_id",  limit: 4
  end

  add_index "updates", ["person_id"], name: "index_updates_on_person_id", using: :btree

  create_table "verifications", force: :cascade do |t|
    t.string   "email",        limit: 255
    t.string   "mobile_phone", limit: 25
    t.integer  "code",         limit: 4
    t.boolean  "verified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id",      limit: 4
    t.string   "carrier",      limit: 100
  end

  create_table "verses", force: :cascade do |t|
    t.string   "reference",   limit: 50
    t.text     "text",        limit: 65535
    t.string   "translation", limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "book",        limit: 4
    t.integer  "chapter",     limit: 4
    t.integer  "verse",       limit: 4
    t.integer  "site_id",     limit: 4
  end

end
