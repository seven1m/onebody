class FixEncodings < ActiveRecord::Migration
  TABLES = %w(
    admins
    admins_reports
    albums
    attachments
    attendance_records
    checkin_folders
    checkin_labels
    checkin_times
    comments
    custom_field_values
    custom_fields
    custom_reports
    document_folder_groups
    document_folders
    documents
    families
    friendship_requests
    friendships
    generated_files
    group_times
    groups
    import_rows
    imports
    jobs
    membership_requests
    memberships
    messages
    news_items
    pages
    people
    people_verses
    pictures
    prayer_requests
    prayer_signups
    processed_messages
    recipes
    relationships
    reports
    service_categories
    services
    sessions
    settings
    signin_failures
    sites
    stream_items
    sync_items
    syncs
    taggings
    tags
    tasks
    twitter_messages
    updates
    verifications
    verses
  ).freeze

  COLUMNS = {
    'admins' => [
      ['template_name', 'string', 100],
      ['flags', 'text', 65_535]
    ],
    'albums' => [
      ['name', 'string', 255],
      ['description', 'text', 65_535],
      ['owner_type', 'string', 255]
    ],
    'attachments' => [
      ['name', 'string', 255],
      ['content_type', 'string', 255],
      ['file_file_name', 'string', 255],
      ['file_content_type', 'string', 255],
      ['file_fingerprint', 'string', 50]
    ],
    'attendance_records' => [
      ['first_name', 'string', 255],
      ['last_name', 'string', 255],
      ['family_name', 'string', 255],
      ['age', 'string', 255],
      ['can_pick_up', 'string', 100],
      ['cannot_pick_up', 'string', 100],
      ['medical_notes', 'string', 200],
      ['barcode_id', 'string', 50]
    ],
    'checkin_folders' => [
      ['name', 'string', 255]
    ],
    'checkin_labels' => [
      ['name', 'string', 255],
      ['description', 'string', 1000],
      ['xml', 'text', 65_535]
    ],
    'checkin_times' => [
      ['campus', 'string', 255]
    ],
    'comments' => [
      ['text', 'text', 65_535],
      ['commentable_type', 'string', 255]
    ],
    'custom_field_values' => [
      ['object_type', 'string', 255],
      ['value', 'string', 255]
    ],
    'custom_fields' => [
      ['name', 'string', 50],
      ['format', 'string', 10]
    ],
    'custom_reports' => [
      ['title', 'string', 255],
      ['category', 'string', 255],
      ['header', 'text', 65_535],
      ['body', 'text', 65_535],
      ['footer', 'text', 65_535],
      ['filters', 'string', 255]
    ],
    'document_folders' => [
      ['name', 'string', 255],
      ['description', 'string', 1000],
      ['parent_folder_ids', 'string', 1000],
      ['path', 'string', 1000]
    ],
    'documents' => [
      ['name', 'string', 255],
      ['description', 'string', 1000],
      ['file_file_name', 'string', 255],
      ['file_content_type', 'string', 255],
      ['file_fingerprint', 'string', 50],
      ['preview_file_name', 'string', 255],
      ['preview_content_type', 'string', 255],
      ['preview_fingerprint', 'string', 50]
    ],
    'families' => [
      ['name', 'string', 255],
      ['last_name', 'string', 255],
      ['address1', 'string', 255],
      ['address2', 'string', 255],
      ['city', 'string', 255],
      ['state', 'string', 255],
      ['zip', 'string', 10],
      ['home_phone', 'string', 25],
      ['email', 'string', 255],
      ['barcode_id', 'string', 50],
      ['alternate_barcode_id', 'string', 50],
      ['photo_file_name', 'string', 255],
      ['photo_content_type', 'string', 255],
      ['photo_fingerprint', 'string', 50],
      ['country', 'string', 2]
    ],
    'generated_files' => [
      ['file_file_name', 'string', 255],
      ['file_content_type', 'string', 255],
      ['file_fingerprint', 'string', 50],
      ['job_id', 'string', 50]
    ],
    'group_times' => [
      ['section', 'string', 100]
    ],
    'groups' => [
      ['name', 'string', 100],
      ['description', 'text', 65_535],
      ['meets', 'string', 100],
      ['location', 'string', 100],
      ['directions', 'text', 65_535],
      ['other_notes', 'text', 65_535],
      ['category', 'string', 50],
      ['address', 'string', 255],
      ['link_code', 'string', 255],
      ['gcal_private_link', 'string', 255],
      ['cm_api_list_id', 'string', 50],
      ['photo_file_name', 'string', 255],
      ['photo_content_type', 'string', 255],
      ['photo_fingerprint', 'string', 50],
      ['membership_mode', 'string', 10, default: 'manual'],
      ['share_token', 'string', 50]
    ],
    'import_rows' => [
      ['import_attributes', 'text', 65_535],
      ['attribute_changes', 'text', 65_535],
      ['attribute_errors', 'text', 65_535]
    ],
    'imports' => [
      ['filename', 'string', 255, null: false],
      ['error_message', 'string', 255],
      ['importable_type', 'string', 50, null: false],
      ['mappings', 'text', 65_535]
    ],
    'jobs' => [
      ['command', 'string', 255]
    ],
    'memberships' => [
      ['roles', 'text', 65_535]
    ],
    'messages' => [
      ['subject', 'string', 255],
      ['body', 'mediumtext', 16_777_215],
      ['html_body', 'mediumtext', 16_777_215]
    ],
    'news_items' => [
      ['title', 'string', 255],
      ['link', 'string', 255],
      ['body', 'text', 65_535],
      ['source', 'string', 255]
    ],
    'pages' => [
      ['slug', 'string', 255],
      ['title', 'string', 255],
      ['body', 'text', 65_535],
      ['path', 'string', 255]
    ],
    'people' => [
      ['gender', 'string', 6],
      ['first_name', 'string', 255],
      ['last_name', 'string', 255],
      ['suffix', 'string', 25],
      ['mobile_phone', 'string', 25],
      ['work_phone', 'string', 25],
      ['fax', 'string', 25],
      ['email', 'string', 255],
      ['website', 'string', 255],
      ['classes', 'text', 65_535],
      ['shepherd', 'string', 255],
      ['mail_group', 'string', 1],
      ['encrypted_password', 'string', 100],
      ['business_name', 'string', 100],
      ['business_description', 'text', 65_535],
      ['business_phone', 'string', 25],
      ['business_email', 'string', 255],
      ['business_website', 'string', 255],
      ['about', 'text', 65_535],
      ['testimony', 'text', 65_535],
      ['alternate_email', 'string', 255],
      ['business_category', 'string', 100],
      ['business_address', 'string', 255],
      ['flags', 'string', 255],
      ['parental_consent', 'string', 255],
      ['feed_code', 'string', 50],
      ['twitter_account', 'string', 100],
      ['api_key', 'string', 50],
      ['salt', 'string', 50],
      ['custom_type', 'string', 100],
      ['custom_fields', 'text', 65_535],
      ['can_pick_up', 'string', 100],
      ['cannot_pick_up', 'string', 100],
      ['medical_notes', 'string', 200],
      ['relationships_hash', 'string', 40],
      ['photo_file_name', 'string', 255],
      ['photo_content_type', 'string', 255],
      ['photo_fingerprint', 'string', 50],
      ['description', 'string', 25],
      ['password_hash', 'string', 255],
      ['password_salt', 'string', 255],
      ['facebook_url', 'string', 255],
      ['twitter', 'string', 15],
      ['provider', 'string', 255],
      ['uid', 'string', 255],
      ['alias', 'string', 255]
    ],
    'pictures' => [
      ['original_url', 'string', 1000],
      ['photo_file_name', 'string', 255],
      ['photo_content_type', 'string', 255],
      ['photo_fingerprint', 'string', 50]
    ],
    'prayer_requests' => [
      ['request', 'text', 65_535],
      ['answer', 'text', 65_535]
    ],
    'prayer_signups' => [
      ['other_name', 'string', 100]
    ],
    'processed_messages' => [
      ['header_message_id', 'string', 255]
    ],
    'recipes' => [
      ['title', 'string', 255],
      ['notes', 'text', 65_535],
      ['description', 'text', 65_535],
      ['ingredients', 'text', 65_535],
      ['directions', 'text', 65_535],
      ['prep', 'string', 255],
      ['bake', 'string', 255],
      ['photo_file_name', 'string', 255],
      ['photo_content_type', 'string', 255],
      ['photo_fingerprint', 'string', 50]
    ],
    'relationships' => [
      ['name', 'string', 255],
      ['other_name', 'string', 255]
    ],
    'reports' => [
      ['name', 'string', 255],
      ['definition', 'text', 65_535]
    ],
    'service_categories' => [
      ['name', 'string', 255, null: false],
      ['description', 'text', 65_535]
    ],
    'services' => [
      ['status', 'string', 255, default: 'current', null: false]
    ],
    'sessions' => [
      ['session_id', 'string', 255],
      ['data', 'text', 65_535]
    ],
    'settings' => [
      ['section', 'string', 100],
      ['name', 'string', 100],
      ['format', 'string', 20],
      ['value', 'string', 500],
      ['description', 'string', 500]
    ],
    'signin_failures' => [
      ['email', 'string', 255],
      ['ip', 'string', 255]
    ],
    'sites' => [
      ['name', 'string', 255],
      ['host', 'string', 255],
      ['secondary_host', 'string', 255],
      ['external_guid', 'string', 255, default: '0'],
      ['logo_file_name', 'string', 255],
      ['logo_content_type', 'string', 255],
      ['logo_fingerprint', 'string', 50],
      ['email_host', 'string', 255]
    ],
    'stream_items' => [
      ['title', 'string', 500],
      ['body', 'text', 65_535],
      ['context', 'text', 65_535],
      ['streamable_type', 'string', 255]
    ],
    'sync_items' => [
      ['syncable_type', 'string', 255],
      ['name', 'string', 255],
      ['operation', 'string', 50],
      ['status', 'string', 50],
      ['error_messages', 'text', 65_535]
    ],
    'taggings' => [
      ['taggable_type', 'string', 255]
    ],
    'tags' => [
      ['name', 'string', 50]
    ],
    'tasks' => [
      ['name', 'string', 255],
      ['description', 'text', 65_535]
    ],
    'twitter_messages' => [
      ['message', 'string', 140],
      ['reply', 'string', 140],
      ['twitter_message_id', 'string', 255]
    ],
    'updates' => [
      ['data', 'text', 65_535],
      ['diff', 'text', 65_535]
    ],
    'verifications' => [
      ['email', 'string', 255],
      ['mobile_phone', 'string', 25],
      ['carrier', 'string', 100]
    ],
    'verses' => [
      ['reference', 'string', 50],
      ['text', 'text', 65_535],
      ['translation', 'string', 10]
    ]
  }.freeze

  # rubocop:disable Metrics/LineLength
  INDEXES = {
    %w(families index_family_names)                                          => 'add_index "families", ["last_name", "name"], name: "index_family_names", length: {"last_name"=>191, "name"=>191}, using: :btree',
    %w(pages index_pages_on_path)                                            => 'add_index "pages", ["path"], name: "index_pages_on_path", length: {"path"=>191}, using: :btree',
    %w(people index_people_on_email)                                         => 'add_index "people", ["email"], name: "index_people_on_email", length: {"email"=>191}, using: :btree',
    %w(sessions index_sessions_on_session_id)                                => 'add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", length: {"session_id"=>191}, using: :btree',
    %w(sessions sessions_session_id_index)                                   => nil, # old index -- just drop it
    %w(sites index_sites_on_host)                                            => 'add_index "sites", ["host"], name: "index_sites_on_host", length: {"host"=>191}, using: :btree',
    %w(stream_items index_stream_items_on_streamable_type_and_streamable_id) => 'add_index "stream_items", ["streamable_type", "streamable_id"], name: "index_stream_items_on_streamable_type_and_streamable_id", length: {"streamable_type"=>191, "streamable_id"=>nil}, using: :btree',
    %w(sync_items index_syncable_on_sync_items)                              => 'add_index "sync_items", ["syncable_type", "syncable_id"], name: "index_syncable_on_sync_items", length: {"syncable_type"=>191, "syncable_id"=>nil}, using: :btree',
    %w(taggings index_taggings_on_taggable_id_and_taggable_type)             => 'add_index "taggings", ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", length: {"taggable_id"=>nil, "taggable_type"=>191}, using: :btree'
  }.freeze

  def up
    return if ActiveRecord::Base.connection.adapter_name != 'Mysql2'
    config = ActiveRecord::Base.connection.instance_variable_get(:@config)
    if config[:encoding] != 'utf8mb4'
      puts
      puts <<-ERROR.strip_heredoc
        Please fix your config/database.yml file. It should look like this:

            production:
              adapter: mysql2
              database: onebody
              host: localhost
              username: onebody
              password: onebody
              encoding: utf8mb4
              collation: utf8mb4_unicode_ci

      ERROR
      raise 'bad config'
    end
    execute "ALTER DATABASE #{config[:database]} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    INDEXES.each do |(table, name), string|
      execute "DROP INDEX #{name} on #{table}" rescue puts("index #{name} does not exist")
      eval(string) if string
    end
    TABLES.each do |table|
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
    end
    COLUMNS.each do |table, columns|
      columns.each do |(name, ruby_type, length, options)|
        type = if ruby_type == 'string'
                 "varchar(#{length})"
               else
                 ruby_type
               end
        null = options && options[:null] == false ? 'NOT NULL' : ''
        default = options && options[:default] ? "DEFAULT '#{options[:default]}'" : ''
        execute "ALTER TABLE #{table} MODIFY COLUMN #{name} #{type} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci #{null} #{default}"
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
