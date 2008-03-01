dirname, basename = File.split(File.expand_path(__FILE__))
libdir = File.join dirname, "lib"

$LOAD_PATH.unshift libdir
begin
  require "bj"
ensure
  $LOAD_PATH.shift
end



=begin
require "rubygems"

dir = Gem.dir
path = Gem.path

dirname, basename = File.split(File.expand_path(__FILE__))
gem_home = File.join dirname, "gem_home"
gem_path = [gem_home] #, *path]

Gem.send :use_paths, gem_home, gem_path

begin
  %w[ attributes systemu orderedhash bj ].each do |lib|
    gem lib
    require lib
  end
ensure
  Gem.send :use_paths, dir, path 
end
=end
