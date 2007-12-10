require 'rake/gempackagetask'

PKG_VERSION = "0.1.0"
PKG_NAME = "onebody"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Church online membership directory and social network."
  s.description = "OneBody is Rails app that provides a single church with an online membership directory, groups (with email), publication subscription, along with many social networking features for members, including customizable profile, picture sharing, and more."
  s.has_rdoc = false
  
  s.files = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f| 
     [ /\.$/, /config\/database.yml$/, /config\/database.yml-/, 
     /database\.sqlite/,
     /\.log$/, /^pkg/, /\.svn/, /^vendor\/rails/, /\~$/, 
     /\/\._/, /\/#/ ].any? {|regex| f =~ regex }
  end
  s.require_path = '.'
  s.author = "Tim Morgan"
  s.email = "tim@timmorgan.org"
  s.homepage = "http://beonebody.org"  
  s.rubyforge_project = "onebody"
  s.platform = Gem::Platform::RUBY 
  s.executables = ['onebody']
  
  s.add_dependency("rails", "= 2.0.1")
  s.add_dependency("atom")
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = false
  p.need_zip = false
end
