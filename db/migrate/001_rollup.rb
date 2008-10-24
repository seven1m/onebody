# Rollup Migration
# ================
# If you are upgrading from a previous (0.7.x) version of OneBody,
# be sure to upgrade to the latest release within that series
# (0.7.8 as of this writing) and run the migrations.
# Then you can upgrade to the latest 0.8.x release.

class Rollup < ActiveRecord::Migration
  def self.up
    create_table "admins", :force => true do |t|
      t.column "manage_publications",    :boolean,  :default => false
      t.column "manage_log",             :boolean,  :default => false
      t.column "manage_music",           :boolean,  :default => false
      t.column "view_hidden_properties", :boolean,  :default => false
      t.column "edit_profiles",          :boolean,  :default => false
      t.column "manage_groups",          :boolean,  :default => false
      t.column "manage_shares",          :boolean,  :default => false
      t.column "manage_notes",           :boolean,  :default => false
      t.column "manage_messages",        :boolean,  :default => false
      t.column "view_hidden_profiles",   :boolean,  :default => false
      t.column "manage_prayer_signups",  :boolean,  :default => false
      t.column "manage_comments",        :boolean,  :default => false
      t.column "manage_recipes",         :boolean,  :default => false
      t.column "manage_pictures",        :boolean,  :default => false
      t.column "manage_access",          :boolean,  :default => false
      t.column "view_log",               :boolean,  :default => false
      t.column "manage_updates",         :boolean,  :default => false
      t.column "created_at",             :datetime
      t.column "updated_at",             :datetime
      t.column "site_id",                :integer
      t.column "edit_pages",             :boolean,  :default => false
      t.column "import_data",            :boolean,  :default => false
      t.column "export_data",            :boolean,  :default => false
      t.column "run_reports",            :boolean,  :default => false
    end

    create_table "albums", :force => true do |t|
      t.column "name",        :string
      t.column "description", :text
      t.column "person_id",   :integer
      t.column "site_id",     :integer
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
    end

    create_table "attachments", :force => true do |t|
      t.column "message_id",   :integer
      t.column "name",         :string
      t.column "content_type", :string,   :limit => 50
      t.column "created_at",   :datetime
      t.column "site_id",      :integer
      t.column "page_id",      :integer
    end

    create_table "attendance_records", :force => true do |t|
      t.column "site_id",     :integer
      t.column "person_id",   :integer
      t.column "group_id",    :integer
      t.column "attended_at", :datetime
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
    end

    create_table "comments", :force => true do |t|
      t.column "verse_id",     :integer
      t.column "person_id",    :integer
      t.column "text",         :text
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "recipe_id",    :integer
      t.column "news_item_id", :integer
      t.column "song_id",      :integer
      t.column "note_id",      :integer
      t.column "site_id",      :integer
    end

    create_table "families", :force => true do |t|
      t.column "legacy_id",          :integer
      t.column "name",               :string
      t.column "last_name",          :string
      t.column "suffix",             :string,   :limit => 25
      t.column "address1",           :string
      t.column "address2",           :string
      t.column "city",               :string
      t.column "state",              :string,   :limit => 2
      t.column "zip",                :string,   :limit => 10
      t.column "home_phone",         :string,   :limit => 25
      t.column "email",              :string
      t.column "latitude",           :float
      t.column "longitude",          :float
      t.column "share_address",      :boolean,                :default => true
      t.column "share_mobile_phone", :boolean,                :default => false
      t.column "share_work_phone",   :boolean,                :default => false
      t.column "share_fax",          :boolean,                :default => false
      t.column "share_email",        :boolean,                :default => false
      t.column "share_birthday",     :boolean,                :default => true
      t.column "share_anniversary",  :boolean,                :default => true
      t.column "updated_at",         :datetime
      t.column "wall_enabled",       :boolean,                :default => true
      t.column "visible",            :boolean,                :default => true
      t.column "share_activity",     :boolean,                :default => true
      t.column "site_id",            :integer
      t.column "share_home_phone",   :boolean,                :default => true
      t.column "deleted",            :boolean,                :default => false
    end

    create_table "friendship_requests", :force => true do |t|
      t.column "person_id",  :integer
      t.column "from_id",    :integer
      t.column "rejected",   :boolean,  :default => false
      t.column "created_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "friendships", :force => true do |t|
      t.column "person_id",  :integer
      t.column "friend_id",  :integer
      t.column "created_at", :datetime
      t.column "ordering",   :integer,  :default => 1000
      t.column "site_id",    :integer
    end

    create_table "groups", :force => true do |t|
      t.column "name",              :string,   :limit => 100
      t.column "description",       :text
      t.column "meets",             :string,   :limit => 100
      t.column "location",          :string,   :limit => 100
      t.column "directions",        :text
      t.column "other_notes",       :text
      t.column "category",          :string,   :limit => 50
      t.column "creator_id",        :integer
      t.column "private",           :boolean,                 :default => false
      t.column "address",           :string
      t.column "members_send",      :boolean,                 :default => true
      t.column "leader_id",         :integer
      t.column "updated_at",        :datetime
      t.column "hidden",            :boolean,                 :default => false
      t.column "approved",          :boolean,                 :default => false
      t.column "link_code",         :string
      t.column "parents_of",        :integer
      t.column "site_id",           :integer
      t.column "cached_parents",    :text
      t.column "blog",              :boolean,                 :default => true
      t.column "email",             :boolean,                 :default => true
      t.column "prayer",            :boolean,                 :default => true
      t.column "attendance",        :boolean,                 :default => true
      t.column "legacy_id",         :integer
      t.column "gcal_private_link", :string
    end

    create_table "log_items", :force => true do |t|
      t.column "name",           :string
      t.column "model_name",     :string,   :limit => 50
      t.column "instance_id",    :integer
      t.column "object_changes", :text
      t.column "person_id",      :integer
      t.column "group_id",       :integer
      t.column "created_at",     :datetime
      t.column "reviewed_on",    :datetime
      t.column "reviewed_by",    :integer
      t.column "flagged_on",     :datetime
      t.column "flagged_by",     :string
      t.column "deleted",        :boolean,                :default => false
      t.column "site_id",        :integer
    end

    create_table "membership_requests", :force => true do |t|
      t.column "person_id",  :integer
      t.column "group_id",   :integer
      t.column "created_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "memberships", :force => true do |t|
      t.column "group_id",           :integer
      t.column "person_id",          :integer
      t.column "admin",              :boolean,  :default => false
      t.column "get_email",          :boolean,  :default => true
      t.column "share_address",      :boolean
      t.column "share_mobile_phone", :boolean
      t.column "share_work_phone",   :boolean
      t.column "share_fax",          :boolean
      t.column "share_email",        :boolean
      t.column "share_birthday",     :boolean
      t.column "share_anniversary",  :boolean
      t.column "updated_at",         :datetime
      t.column "code",               :integer
      t.column "site_id",            :integer
      t.column "legacy_id",          :integer
    end

    create_table "messages", :force => true do |t|
      t.column "group_id",     :integer
      t.column "person_id",    :integer
      t.column "to_person_id", :integer
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "parent_id",    :integer
      t.column "subject",      :string
      t.column "body",         :text
      t.column "share_email",  :boolean,  :default => false
      t.column "wall_id",      :integer
      t.column "code",         :integer
      t.column "site_id",      :integer
    end

    create_table "news_items", :force => true do |t|
      t.column "title",     :string
      t.column "link",      :string
      t.column "body",      :text
      t.column "published", :datetime
      t.column "active",    :boolean,  :default => true
      t.column "site_id",   :integer
    end

    create_table "notes", :force => true do |t|
      t.column "person_id",    :integer
      t.column "title",        :string
      t.column "body",         :text
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "original_url", :string
      t.column "deleted",      :boolean,  :default => false
      t.column "group_id",     :integer
      t.column "site_id",      :integer
    end

    create_table "pages", :force => true do |t|
      t.column "slug",       :string
      t.column "title",      :string
      t.column "body",       :text
      t.column "parent_id",  :integer
      t.column "path",       :string
      t.column "published",  :boolean,  :default => true
      t.column "site_id",    :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "navigation", :boolean,  :default => true
      t.column "system",     :boolean,  :default => false
    end

    add_index "pages", ["path"], :name => "index_pages_on_path"
    add_index "pages", ["parent_id"], :name => "index_pages_on_parent_id"

    create_table "people", :force => true do |t|
      t.column "legacy_id",                    :integer
      t.column "family_id",                    :integer
      t.column "sequence",                     :integer
      t.column "gender",                       :string,   :limit => 6
      t.column "first_name",                   :string
      t.column "last_name",                    :string
      t.column "suffix",                       :string,   :limit => 25
      t.column "mobile_phone",                 :string,   :limit => 25
      t.column "work_phone",                   :string,   :limit => 25
      t.column "fax",                          :string,   :limit => 25
      t.column "birthday",                     :datetime
      t.column "email",                        :string
      t.column "email_changed",                :boolean,                 :default => false
      t.column "website",                      :string
      t.column "classes",                      :string
      t.column "shepherd",                     :string
      t.column "mail_group",                   :string,   :limit => 1
      t.column "encrypted_password",           :string,   :limit => 100
      t.column "service_name",                 :string,   :limit => 100
      t.column "service_description",          :text
      t.column "service_phone",                :string,   :limit => 25
      t.column "service_email",                :string
      t.column "service_website",              :string
      t.column "activities",                   :text
      t.column "interests",                    :text
      t.column "music",                        :text
      t.column "tv_shows",                     :text
      t.column "movies",                       :text
      t.column "books",                        :text
      t.column "quotes",                       :text
      t.column "about",                        :text
      t.column "testimony",                    :text
      t.column "share_mobile_phone",           :boolean
      t.column "share_work_phone",             :boolean
      t.column "share_fax",                    :boolean
      t.column "share_email",                  :boolean
      t.column "share_birthday",               :boolean
      t.column "anniversary",                  :datetime
      t.column "updated_at",                   :datetime
      t.column "alternate_email",              :string
      t.column "email_bounces",                :integer,                 :default => 0
      t.column "service_category",             :string,   :limit => 100
      t.column "get_wall_email",               :boolean,                 :default => true
      t.column "account_frozen",               :boolean,                 :default => false
      t.column "wall_enabled",                 :boolean
      t.column "messages_enabled",             :boolean,                 :default => true
      t.column "service_address",              :string
      t.column "flags",                        :string
      t.column "visible",                      :boolean,                 :default => true
      t.column "parental_consent",             :string
      t.column "admin_id",                     :integer
      t.column "friends_enabled",              :boolean,                 :default => true
      t.column "member",                       :boolean,                 :default => false
      t.column "staff",                        :boolean,                 :default => false
      t.column "elder",                        :boolean,                 :default => false
      t.column "deacon",                       :boolean,                 :default => false
      t.column "can_sign_in",                  :boolean,                 :default => false
      t.column "visible_to_everyone",          :boolean,                 :default => false
      t.column "visible_on_printed_directory", :boolean,                 :default => false
      t.column "full_access",                  :boolean,                 :default => false
      t.column "legacy_family_id",             :integer
      t.column "feed_code",                    :string,   :limit => 50
      t.column "share_activity",               :boolean
      t.column "site_id",                      :integer
      t.column "twitter_account",              :string,   :limit => 100
      t.column "api_key",                      :string,   :limit => 50
      t.column "salt",                         :string,   :limit => 50
      t.column "deleted",                      :boolean,                 :default => false
    end

    add_index "people", ["classes"], :name => "index_people_on_classes"

    create_table "people_verses", :id => false, :force => true do |t|
      t.column "person_id", :integer
      t.column "verse_id",  :integer
    end

    create_table "pictures", :force => true do |t|
      t.column "person_id",  :integer
      t.column "created_at", :datetime
      t.column "cover",      :boolean,  :default => false
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
      t.column "album_id",   :integer
    end

    create_table "prayer_requests", :force => true do |t|
      t.column "group_id",    :integer
      t.column "person_id",   :integer
      t.column "request",     :text
      t.column "answer",      :text
      t.column "answered_at", :datetime
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "publications", :force => true do |t|
      t.column "name",        :string
      t.column "description", :text
      t.column "created_at",  :datetime
      t.column "file",        :string
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "recipes", :force => true do |t|
      t.column "person_id",    :integer
      t.column "title",        :string
      t.column "notes",        :text
      t.column "description",  :text
      t.column "ingredients",  :text
      t.column "directions",   :text
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "prep",         :string
      t.column "bake",         :string
      t.column "serving_size", :integer
      t.column "site_id",      :integer
    end

    create_table "remote_accounts", :force => true do |t|
      t.column "site_id",      :integer
      t.column "person_id",    :integer
      t.column "account_type", :string,  :limit => 25
      t.column "username",     :string
      t.column "token",        :string,  :limit => 500
    end

    create_table "scheduled_tasks", :force => true do |t|
      t.column "name",       :string,   :limit => 100
      t.column "command",    :text
      t.column "interval",   :string
      t.column "active",     :boolean,                 :default => true
      t.column "runner",     :boolean,                 :default => true
      t.column "site_id",    :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "sessions", :force => true do |t|
      t.column "session_id", :string
      t.column "data",       :text
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

    create_table "settings", :force => true do |t|
      t.column "section",     :string,   :limit => 100
      t.column "name",        :string,   :limit => 100
      t.column "format",      :string,   :limit => 20
      t.column "value",       :string,   :limit => 500
      t.column "description", :string,   :limit => 500
      t.column "hidden",      :boolean,                 :default => false
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
      t.column "global",      :boolean,                 :default => false
    end

    create_table "signin_failures", :force => true do |t|
      t.column "email",      :string
      t.column "ip",         :string
      t.column "created_at", :datetime
    end

    create_table "sites", :force => true do |t|
      t.column "name",                  :string
      t.column "host",                  :string
      t.column "created_at",            :datetime
      t.column "updated_at",            :datetime
      t.column "secondary_host",        :string
      t.column "max_admins",            :integer
      t.column "max_people",            :integer
      t.column "max_groups",            :integer
      t.column "import_export_enabled", :boolean,  :default => true
      t.column "pages_enabled",         :boolean,  :default => true
      t.column "pictures_enabled",      :boolean,  :default => true
      t.column "publications_enabled",  :boolean,  :default => true
      t.column "active",                :boolean,  :default => true
      t.column "edit_tasks_enabled",    :boolean,  :default => true
    end

    create_table "sync_instances", :force => true do |t|
      t.column "site_id",           :integer
      t.column "owner_id",          :integer
      t.column "person_id",         :integer
      t.column "remote_id",         :integer
      t.column "remote_account_id", :integer
      t.column "account_type",      :string,   :limit => 25
      t.column "created_at",        :datetime
      t.column "updated_at",        :datetime
    end

    create_table "taggings", :force => true do |t|
      t.column "tag_id",        :integer
      t.column "taggable_id",   :integer
      t.column "taggable_type", :string
      t.column "created_at",    :datetime
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

    create_table "tags", :force => true do |t|
      t.column "name",       :string,   :limit => 50
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "twitter_messages", :force => true do |t|
      t.column "twitter_screen_name", :integer
      t.column "person_id",           :integer
      t.column "message",             :string,   :limit => 140
      t.column "reply",               :string,   :limit => 140
      t.column "created_at",          :datetime
      t.column "updated_at",          :datetime
      t.column "site_id",             :integer
    end

    create_table "updates", :force => true do |t|
      t.column "person_id",        :integer
      t.column "first_name",       :string
      t.column "last_name",        :string
      t.column "home_phone",       :string,   :limit => 25
      t.column "mobile_phone",     :string,   :limit => 25
      t.column "work_phone",       :string,   :limit => 25
      t.column "fax",              :string,   :limit => 25
      t.column "address1",         :string
      t.column "address2",         :string
      t.column "city",             :string
      t.column "state",            :string,   :limit => 2
      t.column "zip",              :string,   :limit => 10
      t.column "birthday",         :datetime
      t.column "anniversary",      :datetime
      t.column "created_at",       :datetime
      t.column "complete",         :boolean,                :default => false
      t.column "suffix",           :string,   :limit => 25
      t.column "gender",           :string,   :limit => 6
      t.column "family_name",      :string
      t.column "family_last_name", :string
      t.column "site_id",          :integer
    end

    create_table "verifications", :force => true do |t|
      t.column "email",        :string
      t.column "mobile_phone", :string,   :limit => 25
      t.column "code",         :integer
      t.column "verified",     :boolean
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "site_id",      :integer
    end

    create_table "verses", :force => true do |t|
      t.column "reference",   :string,   :limit => 50
      t.column "text",        :text
      t.column "translation", :string,   :limit => 10
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
      t.column "book",        :integer
      t.column "chapter",     :integer
      t.column "verse",       :integer
      t.column "site_id",     :integer
    end
    
    Site.current = Site.create :name => 'Default', :host => 'example.com'
    Setting.update_all
  end

  def self.down
    %w(admins attachments comments contacts events events_verses families feeds friendship_requests friendships groups log_items membership_requests memberships messages ministries news_items notes people people_verses performances pictures prayer_requests prayer_signups publications recipes recipes_tags sessions setlists settings sites songs songs_tags sync_info tags tags_verses updates verifications verses workers).each do |table|
      drop_table table
    end
  end
end
