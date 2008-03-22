require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'onebody'
  s.version = File.read(File.join(File.dirname(__FILE__), '../../VERSION')).strip.split('-').first
  s.summary = "web-based church directory and social networking software"
  s.description = <<EOF
OneBody is free, open-source, volunteer-built
software that connects churchgoers on the web.
EOF
  s.has_rdoc = false
  s.files = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f| 
     [ /\.$/, /\.log$/, /^pkg/, /\.svn/, /\.git/, /\~$/, /\/\._/, /\/#/ ].any? {|regex| f =~ regex }
  end
  s.require_path = '.'
  s.author = "Tim Morgan"
  s.email = "tim@timmorgan.org"
  s.homepage = "http://beonebody.org"
  s.rubyforge_project = "onebody"
  s.platform = Gem::Platform::RUBY 
  s.executables = ['onebody']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end