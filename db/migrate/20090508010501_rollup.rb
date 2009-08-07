# Rollup Migration
# ================
# If you are upgrading from a previous (0.8.x) version of OneBody,
# be sure to upgrade to the latest release within that series
# (0.8.1 as of this writing) and run the migrations.
# Then you can upgrade to the latest 1.0.x release.

class Rollup < ActiveRecord::Migration
  def self.up
    create_table "admins", :force => true do |t|
      t.boolean  "manage_publications",    :default => false
      t.boolean  "manage_log",             :default => false
      t.boolean  "manage_music",           :default => false
      t.boolean  "view_hidden_properties", :default => false
      t.boolean  "edit_profiles",          :default => false
      t.boolean  "manage_groups",          :default => false
      t.boolean  "manage_shares",          :default => false
      t.boolean  "manage_notes",           :default => false
      t.boolean  "manage_messages",        :default => false
      t.boolean  "view_hidden_profiles",   :default => false
      t.boolean  "manage_prayer_signups",  :default => false
      t.boolean  "manage_comments",        :default => false
      t.boolean  "manage_recipes",         :default => false
      t.boolean  "manage_pictures",        :default => false
      t.boolean  "manage_access",          :default => false
      t.boolean  "view_log",               :default => false
      t.boolean  "manage_updates",         :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "site_id"
      t.boolean  "edit_pages",             :default => false
      t.boolean  "import_data",            :default => false
      t.boolean  "export_data",            :default => false
      t.boolean  "run_reports",            :default => false
      t.boolean  "manage_news",            :default => false
    end

    create_table "albums", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.integer  "person_id"
      t.integer  "site_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "group_id"
    end

    create_table "attachments", :force => true do |t|
      t.integer  "message_id"
      t.string   "name"
      t.string   "content_type", :limit => 50
      t.datetime "created_at"
      t.integer  "site_id"
      t.integer  "page_id"
    end

    create_table "attendance_records", :force => true do |t|
      t.integer  "site_id"
      t.integer  "person_id"
      t.integer  "group_id"
      t.datetime "attended_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "comments", :force => true do |t|
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

    create_table "families", :force => true do |t|
      t.integer  "legacy_id"
      t.string   "name"
      t.string   "last_name"
      t.string   "suffix",             :limit => 25
      t.string   "address1"
      t.string   "address2"
      t.string   "city"
      t.string   "state",              :limit => 10
      t.string   "zip",                :limit => 10
      t.string   "home_phone",         :limit => 25
      t.string   "email"
      t.float    "latitude"
      t.float    "longitude"
      t.boolean  "share_address",                    :default => true
      t.boolean  "share_mobile_phone",               :default => false
      t.boolean  "share_work_phone",                 :default => false
      t.boolean  "share_fax",                        :default => false
      t.boolean  "share_email",                      :default => false
      t.boolean  "share_birthday",                   :default => true
      t.boolean  "share_anniversary",                :default => true
      t.datetime "updated_at"
      t.boolean  "wall_enabled",                     :default => true
      t.boolean  "visible",                          :default => true
      t.boolean  "share_activity",                   :default => true
      t.integer  "site_id"
      t.boolean  "share_home_phone",                 :default => true
      t.boolean  "deleted",                          :default => false
    end

    add_index "families", ["last_name", "name"], :name => "index_family_names"

    create_table "friendship_requests", :force => true do |t|
      t.integer  "person_id"
      t.integer  "from_id"
      t.boolean  "rejected",   :default => false
      t.datetime "created_at"
      t.integer  "site_id"
    end

    add_index "friendship_requests", ["person_id"], :name => "index_friendship_requests_on_person_id"

    create_table "friendships", :force => true do |t|
      t.integer  "person_id"
      t.integer  "friend_id"
      t.datetime "created_at"
      t.integer  "ordering",   :default => 1000
      t.integer  "site_id"
    end

    add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
    add_index "friendships", ["person_id"], :name => "index_friendships_on_person_id"

    create_table "groups", :force => true do |t|
      t.string   "name",                      :limit => 100
      t.text     "description"
      t.string   "meets",                     :limit => 100
      t.string   "location",                  :limit => 100
      t.text     "directions"
      t.text     "other_notes"
      t.string   "category",                  :limit => 50
      t.integer  "creator_id"
      t.boolean  "private",                                  :default => false
      t.string   "address"
      t.boolean  "members_send",                             :default => true
      t.integer  "leader_id"
      t.datetime "updated_at"
      t.boolean  "hidden",                                   :default => false
      t.boolean  "approved",                                 :default => false
      t.string   "link_code"
      t.integer  "parents_of"
      t.integer  "site_id"
      t.boolean  "blog",                                     :default => true
      t.boolean  "email",                                    :default => true
      t.boolean  "prayer",                                   :default => true
      t.boolean  "attendance",                               :default => true
      t.integer  "legacy_id"
      t.string   "gcal_private_link"
      t.boolean  "approval_required_to_join",                :default => true
      t.boolean  "pictures",                                 :default => true
    end

    add_index "groups", ["category"], :name => "index_groups_on_category"

    create_table "log_items", :force => true do |t|
      t.string   "name"
      t.text     "object_changes"
      t.integer  "person_id"
      t.integer  "group_id"
      t.datetime "created_at"
      t.datetime "reviewed_on"
      t.integer  "reviewed_by"
      t.datetime "flagged_on"
      t.string   "flagged_by"
      t.boolean  "deleted",        :default => false
      t.integer  "site_id"
      t.integer  "loggable_id"
      t.string   "loggable_type"
    end

    create_table "membership_requests", :force => true do |t|
      t.integer  "person_id"
      t.integer  "group_id"
      t.datetime "created_at"
      t.integer  "site_id"
    end

    create_table "memberships", :force => true do |t|
      t.integer  "group_id"
      t.integer  "person_id"
      t.boolean  "admin",              :default => false
      t.boolean  "get_email",          :default => true
      t.boolean  "share_address",      :default => false
      t.boolean  "share_mobile_phone", :default => false
      t.boolean  "share_work_phone",   :default => false
      t.boolean  "share_fax",          :default => false
      t.boolean  "share_email",        :default => false
      t.boolean  "share_birthday",     :default => false
      t.boolean  "share_anniversary",  :default => false
      t.datetime "updated_at"
      t.integer  "code"
      t.integer  "site_id"
      t.integer  "legacy_id"
      t.boolean  "share_home_phone",   :default => false
      t.boolean  "auto",               :default => false
    end

    add_index "memberships", ["group_id"], :name => "index_memberships_on_group_id"
    add_index "memberships", ["person_id"], :name => "index_memberships_on_person_id"

    create_table "messages", :force => true do |t|
      t.integer  "group_id"
      t.integer  "person_id"
      t.integer  "to_person_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "parent_id"
      t.string   "subject"
      t.text     "body"
      t.boolean  "share_email",  :default => false
      t.integer  "wall_id"
      t.integer  "code"
      t.integer  "site_id"
      t.text     "html_body"
    end

    add_index "messages", ["created_at"], :name => "index_messages_on_created_at"
    add_index "messages", ["wall_id"], :name => "index_messages_on_wall_id"

    create_table "news_items", :force => true do |t|
      t.string   "title"
      t.string   "link"
      t.text     "body"
      t.datetime "published"
      t.boolean  "active",     :default => true
      t.integer  "site_id"
      t.string   "source"
      t.integer  "person_id"
      t.integer  "sequence"
      t.datetime "expires_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "notes", :force => true do |t|
      t.integer  "person_id"
      t.string   "title"
      t.text     "body"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "original_url"
      t.boolean  "deleted",      :default => false
      t.integer  "group_id"
      t.integer  "site_id"
    end

    create_table "pages", :force => true do |t|
      t.string   "slug"
      t.string   "title"
      t.text     "body"
      t.integer  "parent_id"
      t.string   "path"
      t.boolean  "published",  :default => true
      t.integer  "site_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "navigation", :default => true
      t.boolean  "system",     :default => false
    end

    add_index "pages", ["parent_id"], :name => "index_pages_on_parent_id"
    add_index "pages", ["path"], :name => "index_pages_on_path"

    create_table "people", :force => true do |t|
      t.integer  "legacy_id"
      t.integer  "family_id"
      t.integer  "sequence"
      t.string   "gender",                       :limit => 6
      t.string   "first_name"
      t.string   "last_name"
      t.string   "suffix",                       :limit => 25
      t.string   "mobile_phone",                 :limit => 25
      t.string   "work_phone",                   :limit => 25
      t.string   "fax",                          :limit => 25
      t.datetime "birthday"
      t.string   "email"
      t.boolean  "email_changed",                               :default => false
      t.string   "website"
      t.string   "classes"
      t.string   "shepherd"
      t.string   "mail_group",                   :limit => 1
      t.string   "encrypted_password",           :limit => 100
      t.string   "business_name",                :limit => 100
      t.text     "business_description"
      t.string   "business_phone",               :limit => 25
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
      t.boolean  "share_mobile_phone"
      t.boolean  "share_work_phone"
      t.boolean  "share_fax"
      t.boolean  "share_email"
      t.boolean  "share_birthday"
      t.datetime "anniversary"
      t.datetime "updated_at"
      t.string   "alternate_email"
      t.integer  "email_bounces",                               :default => 0
      t.string   "business_category",            :limit => 100
      t.boolean  "get_wall_email",                              :default => true
      t.boolean  "account_frozen",                              :default => false
      t.boolean  "wall_enabled"
      t.boolean  "messages_enabled",                            :default => true
      t.string   "business_address"
      t.string   "flags"
      t.boolean  "visible",                                     :default => true
      t.string   "parental_consent"
      t.integer  "admin_id"
      t.boolean  "friends_enabled",                             :default => true
      t.boolean  "member",                                      :default => false
      t.boolean  "staff",                                       :default => false
      t.boolean  "elder",                                       :default => false
      t.boolean  "deacon",                                      :default => false
      t.boolean  "can_sign_in",                                 :default => false
      t.boolean  "visible_to_everyone",                         :default => false
      t.boolean  "visible_on_printed_directory",                :default => false
      t.boolean  "full_access",                                 :default => false
      t.integer  "legacy_family_id"
      t.string   "feed_code",                    :limit => 50
      t.boolean  "share_activity"
      t.integer  "site_id"
      t.string   "twitter_account",              :limit => 100
      t.string   "api_key",                      :limit => 50
      t.string   "salt",                         :limit => 50
      t.boolean  "deleted",                                     :default => false
      t.boolean  "child"
      t.string   "custom_type",                  :limit => 100
      t.text     "custom_fields"
      t.boolean  "include_family_on_calendar",                  :default => true
    end

    add_index "people", ["classes"], :name => "index_people_on_classes"
    add_index "people", ["family_id"], :name => "index_people_on_family_id"

    create_table "people_verses", :id => false, :force => true do |t|
      t.integer "person_id"
      t.integer "verse_id"
    end

    create_table "pictures", :force => true do |t|
      t.integer  "person_id"
      t.datetime "created_at"
      t.boolean  "cover",      :default => false
      t.datetime "updated_at"
      t.integer  "site_id"
      t.integer  "album_id"
    end

    create_table "prayer_requests", :force => true do |t|
      t.integer  "group_id"
      t.integer  "person_id"
      t.text     "request"
      t.text     "answer"
      t.datetime "answered_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "site_id"
    end

    create_table "publications", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.datetime "created_at"
      t.string   "file"
      t.datetime "updated_at"
      t.integer  "site_id"
    end

    create_table "recipes", :force => true do |t|
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
    end

    create_table "remote_accounts", :force => true do |t|
      t.integer "site_id"
      t.integer "person_id"
      t.string  "account_type", :limit => 25
      t.string  "username"
      t.string  "token",        :limit => 500
    end

    create_table "service_categories", :force => true do |t|
      t.string  "name",        :null => false
      t.text    "description"
      t.integer "site_id"
    end

    create_table "services", :force => true do |t|
      t.integer  "person_id",                                  :null => false
      t.integer  "service_category_id",                        :null => false
      t.string   "status",              :default => "current", :null => false
      t.integer  "site_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "sessions", :force => true do |t|
      t.string   "session_id"
      t.text     "data"
      t.datetime "updated_at"
      t.datetime "created_at"
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

    create_table "settings", :force => true do |t|
      t.string   "section",     :limit => 100
      t.string   "name",        :limit => 100
      t.string   "format",      :limit => 20
      t.string   "value",       :limit => 500
      t.string   "description", :limit => 500
      t.boolean  "hidden",                     :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "site_id"
      t.boolean  "global",                     :default => false
    end

    create_table "signin_failures", :force => true do |t|
      t.string   "email"
      t.string   "ip"
      t.datetime "created_at"
    end

    create_table "sites", :force => true do |t|
      t.string   "name"
      t.string   "host"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "secondary_host"
      t.integer  "max_admins"
      t.integer  "max_people"
      t.integer  "max_groups"
      t.boolean  "import_export_enabled", :default => true
      t.boolean  "pages_enabled",         :default => true
      t.boolean  "pictures_enabled",      :default => true
      t.boolean  "publications_enabled",  :default => true
      t.boolean  "active",                :default => true
      t.boolean  "twitter_enabled",       :default => false
    end

    add_index "sites", ["host"], :name => "index_sites_on_host"

    create_table "sync_instances", :force => true do |t|
      t.integer  "site_id"
      t.integer  "owner_id"
      t.integer  "person_id"
      t.integer  "remote_id"
      t.integer  "remote_account_id"
      t.string   "account_type",      :limit => 25
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "taggings", :force => true do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.datetime "created_at"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

    create_table "tags", :force => true do |t|
      t.string   "name",       :limit => 50
      t.datetime "updated_at"
      t.integer  "site_id"
    end

    create_table "twitter_messages", :force => true do |t|
      t.integer  "twitter_screen_name"
      t.integer  "person_id"
      t.string   "message",             :limit => 140
      t.string   "reply",               :limit => 140
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "site_id"
      t.string   "twitter_message_id"
    end

    create_table "updates", :force => true do |t|
      t.integer  "person_id"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "home_phone",       :limit => 25
      t.string   "mobile_phone",     :limit => 25
      t.string   "work_phone",       :limit => 25
      t.string   "fax",              :limit => 25
      t.string   "address1"
      t.string   "address2"
      t.string   "city"
      t.string   "state",            :limit => 2
      t.string   "zip",              :limit => 10
      t.datetime "birthday"
      t.datetime "anniversary"
      t.datetime "created_at"
      t.boolean  "complete",                       :default => false
      t.string   "suffix",           :limit => 25
      t.string   "gender",           :limit => 6
      t.string   "family_name"
      t.string   "family_last_name"
      t.integer  "site_id"
      t.text     "custom_fields"
    end

    add_index "updates", ["person_id"], :name => "index_updates_on_person_id"

    create_table "verifications", :force => true do |t|
      t.string   "email"
      t.string   "mobile_phone", :limit => 25
      t.integer  "code"
      t.boolean  "verified"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "site_id"
    end

    create_table "verses", :force => true do |t|
      t.string   "reference",   :limit => 50
      t.text     "text"
      t.string   "translation", :limit => 10
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "book"
      t.integer  "chapter"
      t.integer  "verse"
      t.integer  "site_id"
    end
    
    Site.current = Site.create :name => 'Default', :host => 'example.com'
    Setting.update_all
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't roll back from a major release."
  end
end
