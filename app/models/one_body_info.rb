class OneBodyInfo
  RELEASED_VERSION_URL = 'http://beonebody.org/releases/CURRENT.txt'
  DEV_VERSION_URL = 'http://github.com/seven1m/onebody/tree/master/VERSION?raw=true'
  GIT_REVISION_YAML_URL = 'http://github.com/api/v1/yaml/seven1m/onebody/commits/master'
  
  def install_method
    @install_method ||= begin
      if File.exists?(File.join(RAILS_ROOT, 'installed-from-gem')) 
        :gem
      elsif File.exists?(File.join(RAILS_ROOT, '.git'))
        :git
      else
        :manual
      end
    end
  end
  
  def this_version
    ONEBODY_VERSION
  end
  
  def this_revision
    if install_method == :git
      @this_revision ||= File.read(File.join(RAILS_ROOT, '.git/refs/heads/master')).strip
    end
  end
  
  def released_version
    if PHONE_HOME_FOR_VERSION_INFO
      @released_version ||= get_version_from_url(RELEASED_VERSION_URL)
    else
      "Visit #{RELEASED_VERSION_URL} to find out."
    end
  end
  
  def development_version
    if PHONE_HOME_FOR_VERSION_INFO
      @development_version ||= get_version_from_url(DEV_VERSION_URL)
    else
      "Visit #{DEV_VERSION_URL} to find out."
    end
  end
  
  def development_revision
    if PHONE_HOME_FOR_VERSION_INFO
      @development_revision ||= get_revision_from_yaml(open(GIT_REVISION_YAML_URL).read)
    end
  end
  
  def precache_info
    install_method
    this_version
    released_version
    development_version
    development_revision
  end
  
  private
    def get_version_from_url(url)
      open(url).read.strip
    end
    
    def get_revision_from_yaml(yaml)
      YAML::load(yaml)['commits'].first['tree']
    end
end