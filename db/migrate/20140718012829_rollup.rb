# encoding: UTF-8

# Rollup Migration
# ================
# If you are upgrading from a previous (1.x.y or 2.x.y) version of OneBody,
# be sure to upgrade to 3.0.0 first and run the database migrations.

class Rollup < ActiveRecord::Migration[4.2]

  create_table "admins", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
    t.string   "template_name", limit: 100
    t.text     "flags"
    t.boolean  "super_admin",               default: false
  end

  add_index "admins", ["site_id"], name: "index_site_id_on_admins", using: :btree

  create_table "admins_reports", id: false, force: true do |t|
    t.integer "admin_id"
    t.integer "report_id"
  end

  create_table "albums", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_public",   default: false
    t.integer  "owner_id"
    t.string   "owner_type"
  end

  create_table "attachments", force: true do |t|
    t.integer  "message_id"
    t.string   "name"
    t.string   "content_type"
    t.datetime "created_at"
    t.integer  "site_id"
    t.integer  "page_id"
    t.integer  "group_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.string   "file_fingerprint",  limit: 50
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  create_table "attendance_records", force: true do |t|
    t.integer  "site_id"
    t.integer  "person_id"
    t.integer  "group_id"
    t.datetime "attended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "family_name"
    t.string   "age"
    t.string   "can_pick_up",    limit: 100
    t.string   "cannot_pick_up", limit: 100
    t.string   "medical_notes",  limit: 200
  end

  add_index "attendance_records", ["attended_at"], name: "index_attended_at_on_attendance_records", using: :btree
  add_index "attendance_records", ["group_id"], name: "index_group_id_on_attendance_records", using: :btree
  add_index "attendance_records", ["person_id"], name: "index_person_id_on_attendance_records", using: :btree
  add_index "attendance_records", ["site_id"], name: "index_site_id_on_attendance_records", using: :btree

  create_table "checkin_times", force: true do |t|
    t.integer  "weekday"
    t.integer  "time"
    t.datetime "the_datetime"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "campus"
  end

  create_table "comments", force: true do |t|
    t.integer  "verse_id"
    t.integer  "person_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recipe_id"
    t.integer  "news_item_id"
    t.integer  "song_id"
    t.integer  "note_id"
    t.integer  "site_id"
    t.integer  "picture_id"
  end

  create_table "document_folders", force: true do |t|
    t.string   "name"
    t.string   "description",       limit: 1000
    t.boolean  "hidden",                         default: false
    t.integer  "folder_id"
    t.string   "parent_folder_ids", limit: 1000
    t.string   "path",              limit: 1000
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  create_table "documents", force: true do |t|
    t.string   "name"
    t.string   "description",       limit: 1000
    t.integer  "folder_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.string   "file_fingerprint",  limit: 50
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  create_table "families", force: true do |t|
    t.integer  "legacy_id"
    t.string   "name"
    t.string   "last_name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state",                limit: 10
    t.string   "zip",                  limit: 10
    t.string   "home_phone",           limit: 25
    t.string   "email"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "updated_at"
    t.boolean  "visible",                         default: true
    t.integer  "site_id"
    t.boolean  "deleted",                         default: false
    t.string   "barcode_id",           limit: 50
    t.datetime "barcode_assigned_at"
    t.boolean  "barcode_id_changed",              default: false
    t.string   "alternate_barcode_id", limit: 50
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_fingerprint",    limit: 50
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  add_index "families", ["last_name", "name"], name: "index_family_names", using: :btree

  create_table "friendship_requests", force: true do |t|
    t.integer  "person_id"
    t.integer  "from_id"
    t.boolean  "rejected",   default: false
    t.datetime "created_at"
    t.integer  "site_id"
  end

  add_index "friendship_requests", ["person_id"], name: "index_friendship_requests_on_person_id", using: :btree

  create_table "friendships", force: true do |t|
    t.integer  "person_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.integer  "ordering",   default: 1000
    t.integer  "site_id"
  end

  add_index "friendships", ["friend_id"], name: "index_friendships_on_friend_id", using: :btree
  add_index "friendships", ["person_id"], name: "index_friendships_on_person_id", using: :btree

  create_table "generated_files", force: true do |t|
    t.integer  "site_id"
    t.integer  "job_id"
    t.integer  "person_id"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.string   "file_fingerprint",  limit: 50
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "group_times", force: true do |t|
    t.integer  "group_id"
    t.integer  "checkin_time_id"
    t.boolean  "print_nametag",                   default: false
    t.integer  "ordering"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "section",             limit: 100
    t.boolean  "print_extra_nametag",             default: false
  end

  create_table "groups", force: true do |t|
    t.string   "name",                      limit: 100
    t.text     "description"
    t.string   "meets",                     limit: 100
    t.string   "location",                  limit: 100
    t.text     "directions"
    t.text     "other_notes"
    t.string   "category",                  limit: 50
    t.integer  "creator_id"
    t.boolean  "private",                               default: false
    t.string   "address"
    t.boolean  "members_send",                          default: true
    t.integer  "leader_id"
    t.datetime "updated_at"
    t.boolean  "hidden",                                default: false
    t.boolean  "approved",                              default: false
    t.string   "link_code"
    t.integer  "parents_of"
    t.integer  "site_id"
    t.boolean  "blog",                                  default: true
    t.boolean  "email",                                 default: true
    t.boolean  "prayer",                                default: true
    t.boolean  "attendance",                            default: true
    t.integer  "legacy_id"
    t.string   "gcal_private_link"
    t.boolean  "approval_required_to_join",             default: true
    t.boolean  "pictures",                              default: true
    t.string   "cm_api_list_id",            limit: 50
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_fingerprint",         limit: 50
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.datetime "created_at"
    t.float    "latitude"
    t.float    "longitude"
  end

  add_index "groups", ["category"], name: "index_groups_on_category", using: :btree
  add_index "groups", ["site_id"], name: "index_site_id_on_groups", using: :btree

  create_table "jobs", force: true do |t|
    t.integer  "site_id"
    t.string   "command"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "membership_requests", force: true do |t|
    t.integer  "person_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.integer  "site_id"
  end

  create_table "memberships", force: true do |t|
    t.integer  "group_id"
    t.integer  "person_id"
    t.boolean  "admin",              default: false
    t.boolean  "get_email",          default: true
    t.boolean  "share_address",      default: false
    t.boolean  "share_mobile_phone", default: false
    t.boolean  "share_work_phone",   default: false
    t.boolean  "share_fax",          default: false
    t.boolean  "share_email",        default: false
    t.boolean  "share_birthday",     default: false
    t.boolean  "share_anniversary",  default: false
    t.datetime "updated_at"
    t.integer  "code"
    t.integer  "site_id"
    t.integer  "legacy_id"
    t.boolean  "share_home_phone",   default: false
    t.boolean  "auto",               default: false
    t.datetime "created_at"
    t.text     "roles"
  end

  add_index "memberships", ["group_id"], name: "index_memberships_on_group_id", using: :btree
  add_index "memberships", ["person_id"], name: "index_memberships_on_person_id", using: :btree

  create_table "messages", force: true do |t|
    t.integer  "group_id"
    t.integer  "person_id"
    t.integer  "to_person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "subject"
    t.text     "body"
    t.boolean  "share_email",  default: false
    t.integer  "code"
    t.integer  "site_id"
    t.text     "html_body"
  end

  add_index "messages", ["created_at"], name: "index_messages_on_created_at", using: :btree

  create_table "news_items", force: true do |t|
    t.string   "title"
    t.string   "link"
    t.text     "body"
    t.datetime "published"
    t.boolean  "active",     default: true
    t.integer  "site_id"
    t.string   "source"
    t.integer  "person_id"
    t.integer  "sequence"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notes", force: true do |t|
    t.integer  "person_id"
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "original_url"
    t.integer  "group_id"
    t.integer  "site_id"
  end

  create_table "pages", force: true do |t|
    t.string   "slug"
    t.string   "title"
    t.text     "body"
    t.integer  "parent_id"
    t.string   "path"
    t.boolean  "published",  default: true
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "navigation", default: true
    t.boolean  "system",     default: false
    t.boolean  "raw",        default: false
  end

  add_index "pages", ["parent_id"], name: "index_pages_on_parent_id", using: :btree
  add_index "pages", ["path"], name: "index_pages_on_path", using: :btree

  create_table "people", force: true do |t|
    t.integer  "legacy_id"
    t.integer  "family_id"
    t.integer  "sequence"
    t.string   "gender",                       limit: 6
    t.string   "first_name"
    t.string   "last_name"
    t.string   "suffix",                       limit: 25
    t.string   "mobile_phone",                 limit: 25
    t.string   "work_phone",                   limit: 25
    t.string   "fax",                          limit: 25
    t.datetime "birthday"
    t.string   "email"
    t.boolean  "email_changed",                            default: false
    t.string   "website"
    t.text     "classes"
    t.string   "shepherd"
    t.string   "mail_group",                   limit: 1
    t.string   "encrypted_password",           limit: 100
    t.string   "business_name",                limit: 100
    t.text     "business_description"
    t.string   "business_phone",               limit: 25
    t.string   "business_email"
    t.string   "business_website"
    t.text     "activities"
    t.text     "interests"
    t.text     "music"
    t.text     "tv_shows"
    t.text     "movies"
    t.text     "books"
    t.text     "quotes"
    t.text     "about"
    t.text     "testimony"
    t.boolean  "share_mobile_phone",                       default: false
    t.boolean  "share_work_phone",                         default: false
    t.boolean  "share_fax",                                default: false
    t.boolean  "share_email",                              default: false
    t.boolean  "share_birthday",                           default: true
    t.datetime "anniversary"
    t.datetime "updated_at"
    t.string   "alternate_email"
    t.integer  "email_bounces",                            default: 0
    t.string   "business_category",            limit: 100
    t.boolean  "account_frozen",                           default: false
    t.boolean  "messages_enabled",                         default: true
    t.string   "business_address"
    t.string   "flags"
    t.boolean  "visible",                                  default: true
    t.string   "parental_consent"
    t.integer  "admin_id"
    t.boolean  "friends_enabled",                          default: true
    t.boolean  "member",                                   default: false
    t.boolean  "staff",                                    default: false
    t.boolean  "elder",                                    default: false
    t.boolean  "deacon",                                   default: false
    t.boolean  "can_sign_in",                              default: false
    t.boolean  "visible_to_everyone",                      default: false
    t.boolean  "visible_on_printed_directory",             default: false
    t.boolean  "full_access",                              default: false
    t.integer  "legacy_family_id"
    t.string   "feed_code",                    limit: 50
    t.boolean  "share_activity",                           default: true
    t.integer  "site_id"
    t.string   "twitter_account",              limit: 100
    t.string   "api_key",                      limit: 50
    t.string   "salt",                         limit: 50
    t.boolean  "deleted",                                  default: false
    t.boolean  "child"
    t.string   "custom_type",                  limit: 100
    t.text     "custom_fields"
    t.string   "can_pick_up",                  limit: 100
    t.string   "cannot_pick_up",               limit: 100
    t.string   "medical_notes",                limit: 200
    t.string   "relationships_hash",           limit: 40
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_fingerprint",            limit: 50
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "description",                  limit: 25
    t.boolean  "share_anniversary",                        default: true
    t.boolean  "share_address",                            default: true
    t.boolean  "share_home_phone",                         default: true
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at"
  end

  add_index "people", ["admin_id"], name: "index_admin_id_on_people", using: :btree
  add_index "people", ["business_category"], name: "index_business_category_on_people", using: :btree
  add_index "people", ["family_id"], name: "index_people_on_family_id", using: :btree
  add_index "people", ["site_id"], name: "index_site_id_on_people", using: :btree

  create_table "people_verses", id: false, force: true do |t|
    t.integer "person_id"
    t.integer "verse_id"
  end

  create_table "pictures", force: true do |t|
    t.integer  "person_id"
    t.datetime "created_at"
    t.boolean  "cover",                           default: false
    t.datetime "updated_at"
    t.integer  "site_id"
    t.integer  "album_id"
    t.string   "original_url",       limit: 1000
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_fingerprint",  limit: 50
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  add_index "pictures", ["album_id"], name: "index_pictures_on_album_id", using: :btree

  create_table "prayer_requests", force: true do |t|
    t.integer  "group_id"
    t.integer  "person_id"
    t.text     "request"
    t.text     "answer"
    t.datetime "answered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  create_table "prayer_signups", force: true do |t|
    t.integer  "person_id"
    t.datetime "start"
    t.datetime "created_at"
    t.boolean  "reminded",               default: false
    t.string   "other_name", limit: 100
    t.integer  "site_id"
  end

  create_table "processed_messages", force: true do |t|
    t.string   "header_message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recipes", force: true do |t|
    t.integer  "person_id"
    t.string   "title"
    t.text     "notes"
    t.text     "description"
    t.text     "ingredients"
    t.text     "directions"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prep"
    t.string   "bake"
    t.integer  "serving_size"
    t.integer  "site_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.string   "photo_fingerprint",  limit: 50
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "relationships", force: true do |t|
    t.integer  "person_id"
    t.integer  "related_id"
    t.string   "name"
    t.string   "other_name"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", force: true do |t|
    t.integer  "site_id"
    t.string   "name"
    t.text     "definition"
    t.boolean  "restricted",     default: true
    t.integer  "created_by_id"
    t.integer  "run_count",      default: 0
    t.datetime "last_run_at"
    t.integer  "last_run_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "service_categories", force: true do |t|
    t.string  "name",        null: false
    t.text    "description"
    t.integer "site_id"
  end

  create_table "services", force: true do |t|
    t.integer  "person_id",                               null: false
    t.integer  "service_category_id",                     null: false
    t.string   "status",              default: "current", null: false
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
    t.datetime "created_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree

  create_table "settings", force: true do |t|
    t.string   "section",     limit: 100
    t.string   "name",        limit: 100
    t.string   "format",      limit: 20
    t.string   "value",       limit: 500
    t.string   "description", limit: 500
    t.boolean  "hidden",                  default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
    t.boolean  "global",                  default: false
  end

  create_table "signin_failures", force: true do |t|
    t.string   "email"
    t.string   "ip"
    t.datetime "created_at"
  end

  create_table "sites", force: true do |t|
    t.string   "name"
    t.string   "host"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "secondary_host"
    t.integer  "max_admins"
    t.integer  "max_people"
    t.integer  "max_groups"
    t.boolean  "import_export_enabled",            default: true
    t.boolean  "pages_enabled",                    default: true
    t.boolean  "pictures_enabled",                 default: true
    t.boolean  "publications_enabled",             default: true
    t.boolean  "active",                           default: true
    t.boolean  "twitter_enabled",                  default: false
    t.string   "external_guid",                    default: "0"
    t.datetime "settings_changed_at"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.string   "logo_fingerprint",      limit: 50
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "email_host"
  end

  add_index "sites", ["host"], name: "index_sites_on_host", using: :btree

  create_table "stream_items", force: true do |t|
    t.integer  "site_id"
    t.string   "title",           limit: 500
    t.text     "body"
    t.text     "context"
    t.integer  "person_id"
    t.integer  "group_id"
    t.integer  "streamable_id"
    t.string   "streamable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "shared"
    t.boolean  "text",                        default: false
    t.boolean  "is_public"
    t.boolean  "false"
  end

  add_index "stream_items", ["created_at"], name: "index_stream_items_on_created_at", using: :btree
  add_index "stream_items", ["group_id"], name: "index_stream_items_on_group_id", using: :btree
  add_index "stream_items", ["person_id"], name: "index_stream_items_on_person_id", using: :btree
  add_index "stream_items", ["streamable_type", "streamable_id"], name: "index_stream_items_on_streamable_type_and_streamable_id", using: :btree

  create_table "sync_items", force: true do |t|
    t.integer "site_id"
    t.integer "sync_id"
    t.integer "syncable_id"
    t.string  "syncable_type"
    t.integer "legacy_id"
    t.string  "name"
    t.string  "operation",      limit: 50
    t.string  "status",         limit: 50
    t.text    "error_messages"
  end

  add_index "sync_items", ["sync_id"], name: "index_sync_id_on_sync_items", using: :btree
  add_index "sync_items", ["syncable_type", "syncable_id"], name: "index_syncable_on_sync_items", using: :btree

  create_table "syncs", force: true do |t|
    t.integer  "site_id"
    t.integer  "person_id"
    t.boolean  "complete",      default: false
    t.integer  "success_count"
    t.integer  "error_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.datetime "finished_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree

  create_table "tags", force: true do |t|
    t.string   "name",       limit: 50
    t.datetime "updated_at"
    t.integer  "site_id"
  end

  create_table "twitter_messages", force: true do |t|
    t.integer  "twitter_screen_name"
    t.integer  "person_id"
    t.string   "message",             limit: 140
    t.string   "reply",               limit: 140
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
    t.string   "twitter_message_id"
  end

  create_table "updates", force: true do |t|
    t.integer  "person_id"
    t.datetime "created_at"
    t.boolean  "complete",   default: false
    t.integer  "site_id"
    t.text     "data"
    t.text     "diff"
    t.integer  "family_id"
  end

  add_index "updates", ["person_id"], name: "index_updates_on_person_id", using: :btree

  create_table "verifications", force: true do |t|
    t.string   "email"
    t.string   "mobile_phone", limit: 25
    t.integer  "code"
    t.boolean  "verified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
    t.string   "carrier",      limit: 100
  end

  create_table "verses", force: true do |t|
    t.string   "reference",   limit: 50
    t.text     "text"
    t.string   "translation", limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "book"
    t.integer  "chapter"
    t.integer  "verse"
    t.integer  "site_id"
  end

end
