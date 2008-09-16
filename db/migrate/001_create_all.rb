class CreateAll < ActiveRecord::Migration
  def self.up
    create_table "admins" do |t|
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
      t.column "manage_events",          :boolean,  :default => false
      t.column "manage_recipes",         :boolean,  :default => false
      t.column "manage_pictures",        :boolean,  :default => false
      t.column "manage_access",          :boolean,  :default => false
      t.column "view_log",               :boolean,  :default => false
      t.column "manage_updates",         :boolean,  :default => false
      t.column "created_at",             :datetime
      t.column "updated_at",             :datetime
      t.column "site_id",                :integer
    end

    create_table "attachments" do |t|
      t.column "message_id",   :integer
      t.column "name",         :string
      t.column "file",         :binary,   :limit => 10485760
      t.column "content_type", :string,   :limit => 50
      t.column "created_at",   :datetime
      t.column "song_id",      :integer
      t.column "site_id",      :integer
    end

    create_table "comments" do |t|
      t.column "verse_id",     :integer
      t.column "person_id",    :integer
      t.column "text",         :text
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "event_id",     :integer
      t.column "recipe_id",    :integer
      t.column "news_item_id", :integer
      t.column "song_id",      :integer
      t.column "note_id",      :integer
      t.column "site_id",      :integer
    end

    create_table "contacts" do |t|
      t.column "person_id",  :integer
      t.column "owner_id",   :integer
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "events" do |t|
      t.column "person_id",   :integer
      t.column "name",        :string
      t.column "description", :text
      t.column "when",        :datetime
      t.column "created_at",  :datetime
      t.column "open",        :boolean,  :default => false
      t.column "admins",      :text
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "events_verses", :id => false do |t|
      t.column "event_id", :integer
      t.column "verse_id", :integer
    end

    create_table "families" do |t|
      t.column "legacy_id",          :integer
      t.column "name",               :string
      t.column "last_name",          :string
      t.column "suffix",             :string,   :limit => 25
      t.column "address1",           :string
      t.column "address2",           :string
      t.column "city",               :string
      t.column "state",              :string,   :limit => 2
      t.column "zip",                :string,   :limit => 10
      t.column "home_phone",         :integer
      t.column "email",              :string
      t.column "latitude",           :float
      t.column "longitude",          :float
      t.column "mail_group",         :string,   :limit => 1
      t.column "security_token",     :string,   :limit => 25
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
    end

    create_table "feeds" do |t|
      t.column "person_id",  :integer
      t.column "group_id",   :integer
      t.column "name",       :string
      t.column "url",        :string,   :limit => 500
      t.column "spec",       :string,   :limit => 5
      t.column "fetched_at", :datetime
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "friendship_requests" do |t|
      t.column "person_id",  :integer
      t.column "from_id",    :integer
      t.column "rejected",   :boolean,  :default => false
      t.column "created_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "friendships" do |t|
      t.column "person_id",  :integer
      t.column "friend_id",  :integer
      t.column "created_at", :datetime
      t.column "ordering",   :integer,  :default => 1000
      t.column "site_id",    :integer
    end

    create_table "groups" do |t|
      t.column "name",         :string,   :limit => 100
      t.column "description",  :text
      t.column "meets",        :string,   :limit => 100
      t.column "location",     :string,   :limit => 100
      t.column "directions",   :text
      t.column "other_notes",  :text
      t.column "category",     :string,   :limit => 50
      t.column "creator_id",   :integer
      t.column "private",      :boolean,                 :default => false
      t.column "address",      :string
      t.column "members_send", :boolean,                 :default => true
      t.column "leader_id",    :integer
      t.column "updated_at",   :datetime
      t.column "hidden",       :boolean,                 :default => false
      t.column "approved",     :boolean,                 :default => false
      t.column "link_code",    :string
      t.column "parents_of",   :integer
      t.column "site_id",      :integer
    end

    create_table "log_items" do |t|
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

    create_table "membership_requests" do |t|
      t.column "person_id",  :integer
      t.column "group_id",   :integer
      t.column "created_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "memberships" do |t|
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
    end

    create_table "messages" do |t|
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

    create_table "ministries" do |t|
      t.column "admin_id",    :integer
      t.column "name",        :string,   :limit => 100
      t.column "description", :text
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "news_items" do |t|
      t.column "title",     :string
      t.column "link",      :string
      t.column "body",      :text
      t.column "published", :datetime
      t.column "active",    :boolean,  :default => true
      t.column "site_id",   :integer
    end

    create_table "notes" do |t|
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

    create_table "people" do |t|
      t.column "legacy_id",                    :integer
      t.column "family_id",                    :integer
      t.column "sequence",                     :integer
      t.column "gender",                       :string,   :limit => 6
      t.column "first_name",                   :string
      t.column "last_name",                    :string
      t.column "suffix",                       :string,   :limit => 25
      t.column "mobile_phone",                 :integer
      t.column "work_phone",                   :integer
      t.column "fax",                          :integer
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
      t.column "service_phone",                :integer
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
      t.column "music_access",                 :boolean,                 :default => false
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
    end

    create_table "people_verses", :id => false do |t|
      t.column "person_id", :integer
      t.column "verse_id",  :integer
    end

    create_table "performances" do |t|
      t.column "setlist_id", :integer
      t.column "song_id",    :integer
      t.column "ordering",   :integer
      t.column "site_id",    :integer
    end

    create_table "pictures" do |t|
      t.column "event_id",   :integer
      t.column "person_id",  :integer
      t.column "created_at", :datetime
      t.column "cover",      :boolean,  :default => false
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "prayer_requests" do |t|
      t.column "group_id",    :integer
      t.column "person_id",   :integer
      t.column "request",     :text
      t.column "answer",      :text
      t.column "answered_at", :datetime
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "prayer_signups" do |t|
      t.column "person_id",  :integer
      t.column "start",      :datetime
      t.column "created_at", :datetime
      t.column "reminded",   :boolean,                 :default => false
      t.column "other",      :string,   :limit => 100
      t.column "site_id",    :integer
    end

    create_table "publications" do |t|
      t.column "name",        :string
      t.column "description", :text
      t.column "created_at",  :datetime
      t.column "file",        :string
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
    end

    create_table "recipes" do |t|
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
      t.column "event_id",     :integer
      t.column "site_id",      :integer
    end

    create_table "recipes_tags", :id => false do |t|
      t.column "tag_id",    :integer
      t.column "recipe_id", :integer
    end

    create_table "sessions" do |t|
      t.column "session_id", :string
      t.column "data",       :text
      t.column "updated_at", :datetime
      t.column "created_at", :datetime
    end

    add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

    create_table "setlists" do |t|
      t.column "start",      :datetime
      t.column "person_id",  :integer
      t.column "created_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "settings" do |t|
      t.column "section",     :string,   :limit => 100
      t.column "name",        :string,   :limit => 100
      t.column "format",      :string,   :limit => 20
      t.column "value",       :string
      t.column "description", :string,   :limit => 500
      t.column "hidden",      :boolean,                 :default => false
      t.column "created_at",  :datetime
      t.column "updated_at",  :datetime
      t.column "site_id",     :integer
      t.column "global",      :boolean,                 :default => false
    end
    
    create_table "sites", :force => true do |t|
      t.column "name",       :string
      t.column "host",       :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "songs" do |t|
      t.column "title",            :string
      t.column "notes",            :text
      t.column "artists",          :string,   :limit => 500
      t.column "album",            :string
      t.column "image_small_url",  :string
      t.column "image_medium_url", :string
      t.column "image_large_url",  :string
      t.column "amazon_asin",      :string,   :limit => 50
      t.column "amazon_url",       :string
      t.column "created_at",       :datetime
      t.column "person_id",        :integer
      t.column "site_id",          :integer
    end

    create_table "songs_tags", :id => false do |t|
      t.column "song_id", :integer
      t.column "tag_id",  :integer
    end

    create_table "sync_info", :id => false do |t|
      t.column "last_update", :datetime
    end

    create_table "tags" do |t|
      t.column "name",       :string,   :limit => 50
      t.column "updated_at", :datetime
      t.column "site_id",    :integer
    end

    create_table "tags_verses", :id => false do |t|
      t.column "tag_id",   :integer
      t.column "verse_id", :integer
    end

    create_table "updates" do |t|
      t.column "person_id",        :integer
      t.column "first_name",       :string
      t.column "last_name",        :string
      t.column "home_phone",       :bigint
      t.column "mobile_phone",     :bigint
      t.column "work_phone",       :bigint
      t.column "fax",              :bigint
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

    create_table "verifications" do |t|
      t.column "email",        :string
      t.column "mobile_phone", :bigint
      t.column "code",         :integer
      t.column "verified",     :boolean
      t.column "created_at",   :datetime
      t.column "updated_at",   :datetime
      t.column "site_id",      :integer
    end

    create_table "verses" do |t|
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

    create_table "workers" do |t|
      t.column "ministry_id", :integer
      t.column "person_id",   :integer
      t.column "start",       :datetime
      t.column "end",         :datetime
      t.column "remind_on",   :datetime
      t.column "reminded",    :boolean,  :default => false
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
