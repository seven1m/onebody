RAILS_ROOT = File.dirname(__FILE__) + "/../.."
require 'time'

namespace :onebody do
  namespace :version do
    task :update do
      File.open(RAILS_ROOT + '/VERSION', 'w') do |file|
        file.write Time.now.strftime('0.%Y.%j.%H').sub(/^0.20+/, '0.')
      end
    end
  end
end