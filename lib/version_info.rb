require_relative './version'

# Mix this module into the main application module to provide
# information about the current version, latest version,
# and whether the app is up-to-date.
#
# In config/application.rb:
#
#     module OneBody
#       extend VersionInfo
#     end
#
module VersionInfo
  GITHUB_REPO_OWNER = 'churchio'.freeze
  GITHUB_REPO_NAME = 'onebody'.freeze

  def current_version
    @current_version ||= Version.from_string(current_version_string)
  end

  def latest_version
    string = Rails.cache.fetch('latest_version', expires_in: 1.hour) do
      Github.repos.releases.all(GITHUB_REPO_OWNER, GITHUB_REPO_NAME).first['tag_name']
    end
    Version.from_string(string)
  rescue Github::Error::ServiceError, Faraday::ConnectionFailed
    nil
  end

  def up_to_date?
    current_version >= latest_version
  end

  private

  def current_version_path
    Rails.root.join('VERSION')
  end

  def current_version_string
    File.read(current_version_path).strip
  end
end
