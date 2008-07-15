require 'zlib'
require 'archive/tar/minitar'

class OneBodyInfo
  RELEASED_VERSION_URL = nil
  DEV_VERSION_URL = 'http://github.com/seven1m/onebody/tree/master%2FVERSION?raw=true'
  GIT_REVISION_YAML_URL = 'http://github.com/api/v1/yaml/seven1m/onebody/commits/master'
  
  include Archive::Tar
  
  cattr_accessor :setup_environment
  
  def install_method
    @install_method ||= begin
      if File.exists?(File.join(RAILS_ROOT, '.git'))
        :git
      else
        :manual
      end
    end
  end
  
  def git_install_method?
    install_method == :git
  end
  
  def this_version
    ONEBODY_VERSION
  end
  
  def this_revision
    if install_method == :git
      @this_revision ||= begin
        # we want to do this without running any real git command on the system
        # this might not be the best way to get this information, but seems to work
        if File.exists?(head = File.join(RAILS_ROOT, '.git/refs/heads/master'))
          File.read(head).strip
        elsif File.exists?(head = File.join(RAILS_ROOT, '.git/logs/HEAD'))
          File.read(head).split[1]
        else
          '???'
        end
      end
    end
  end
  
  def released_version
    if RELEASED_VERSION_URL
      if PHONE_HOME_FOR_VERSION_INFO
        @released_version ||= get_version_from_url(RELEASED_VERSION_URL)
      else
        "Visit #{RELEASED_VERSION_URL} to find out."
      end
    end
  end
  
  def development_version
    if DEV_VERSION_URL
      if PHONE_HOME_FOR_VERSION_INFO
        @development_version ||= get_version_from_url(DEV_VERSION_URL)
      else
        "Visit #{DEV_VERSION_URL} to find out."
      end
    end
  end
  
  def development_revision
    if PHONE_HOME_FOR_VERSION_INFO
      @development_revision ||= get_revision_from_yaml(open(GIT_REVISION_YAML_URL).read)
    end
  end
  
  def up_to_date
    if PHONE_HOME_FOR_VERSION_INFO
      this_version >= development_version
    end
  end
  
  def database_config
    @database_config ||= database_yaml[OneBodyInfo.setup_environment]
  end
  
  def database_yaml
    YAML::load_file(database_config_filename)
  end
  
  def edit_database(config)
    yaml = build_database_config(config)
    backup_database_config
    write_database_config(yaml)
  end
  
  def database_config_filename
    File.join(RAILS_ROOT, 'config/database.yml')
  end
  
  def backup_database_config
    backup_filename = database_config_filename + '.backup'
    File.delete(backup_filename) if File.exists?(backup_filename)
    File.open(backup_filename, 'w') { |f| f.write File.read(database_config_filename) }
  end
  
  def write_database_config(config)
    File.open(database_config_filename, 'w') do |file|
      YAML::dump(config, file)
    end
  end
  
  def test_database_config(config)
    connect_to_database(build_database_config(config)[OneBodyInfo.setup_environment])
  end
  
  def build_database_config(config)
    settings = {
      'adapter'  => config[:adapter],
      'database' => config[:database]
    }
    if config[:adapter] == 'mysql'
      raise 'Database passwords do not match.' if config[:password] != config[:password_confirm]
      settings.update({
        'username' => config[:username],
        'password' => config[:password]
      })
    end
    yaml = database_yaml
    yaml[OneBodyInfo.setup_environment] = settings
    yaml
  end
  
  def database_version
    @database_version ||= begin
      if connect_to_database(database_config)
        begin
          ActiveRecord::Base.connection.select_value("SELECT version FROM schema_migrations ORDER BY CAST(version AS UNSIGNED) DESC LIMIT 1").to_i
        rescue
          0
        end
      end
    end
  end
  
  def people_count
    if connect_to_database(database_config)
      ActiveRecord::Base.connection.select_value("SELECT count(*) FROM people").to_i rescue nil
    end
  end
  
  def date_of_last_sync
    if connect_to_database(database_config)
      ActiveRecord::Base.connection.select_value("SELECT last_update FROM sync_info") rescue nil
    end
  end
  
  def scheduler_running?
    File.exists?(File.join(RAILS_ROOT, 'Scheduler.pid'))
  end

  def connect_to_database(config)
    begin
      ActiveRecord::Base.establish_connection(config)
    rescue
      nil
    else
      ActiveRecord::Base.connection
    end
  end
  
  def possible_database_versions
    Dir[File.join(RAILS_ROOT, 'db/migrate/*.rb')].map { |m| File.split(m).last.split('_').first.to_i }.sort
  end
  
  def max_database_version
    possible_database_versions.last
  end
  
  def database_up_to_date
    if database_version
      database_version >= max_database_version
    end
  end
  
  def database_upgrade_code
    "rake db:migrate RAILS_ENV=#{OneBodyInfo.setup_environment}"
  end
  
  def backup_database
    # first backup database
    timestamp = Time.now.strftime('%Y%m%d%H%M')
    base_path = File.join(RAILS_ROOT, 'db')
    base_filename = File.expand_path(File.join(base_path, "#{OneBodyInfo.setup_environment}.backup.#{timestamp}"))
    if database_config['adapter'] == 'mysql'
      filename = base_filename + '.sql'
      `mysqldump -u#{database_config['username']} -p#{database_config['password']} #{database_config['database']} > #{filename}`
    else # sqlite3
      filename = base_filename + '.db'
      FileUtils.cp(File.expand_path(File.join(RAILS_ROOT, database_config['database'])), filename)
    end
    if File.exists? filename
      # now backup photos and publications files
      paths_to_backup = [File.join(base_path, 'photos'), File.join(base_path, 'publications')]
      File.open(base_filename + '.tar', 'wb') { |tar| Minitar.pack(paths_to_backup, tar) }
      filename
    else
      false
    end
  end
  
  def precache
    @install_method = nil;       install_method
    @this_version = nil;         this_version
    @released_version = nil;     released_version
    @development_version = nil;  development_version
    @development_revision = nil; development_revision
    @database_config = nil;      database_config
    @database_version = nil;     database_version
  end
  alias_method :reload, :precache
  
  private
    def get_version_from_url(url)
      open(url).read.strip
    end
    
    def get_revision_from_yaml(yaml)
      YAML::load(yaml)['commits'].first['id']
    end
end
