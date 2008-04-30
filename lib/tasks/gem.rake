RAILS_ROOT = File.dirname(__FILE__) + "/../.."

require 'rubygems'
require 'rake/gempackagetask'

namespace :onebody do
  namespace :gem do
    desc 'Build the onebody.gemspec.'
    task :spec do
      files = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |file|
        [ /\.$/, /\.log$/, /^pkg/, /\.git/, /\~$/, /\/\._/, /\/#/, /\.DS_Store/ ].any? { |regex| file =~ regex }
      end

      spec = File.read(RAILS_ROOT + '/onebody.gemspec')
      spec.sub!(/s\.version\s=\s'\d(\.\d+)+'/, "s.version = '#{File.read(RAILS_ROOT + '/VERSION')}'")
      
      # we must generate a static list of files for the GitHub auto gem build process to work
      spec.sub!(
        /s\.files\s=\s\[.*?\]/m,
        "s.files = [\n    " + files.sort.map { |f| f.inspect }.join(",\n    ") + "\n  ]"
      )

      File.open(RAILS_ROOT + '/onebody.gemspec', 'w') { |f| f.write spec }
    end
    
    #desc 'Generate onebody.gemspec and build gem.'
    #task :build => :spec
    #  load RAILS_ROOT + '/onebody.gemspec'
    #  TODO: figure out command needed to build gem from spec
    #end
  end
end