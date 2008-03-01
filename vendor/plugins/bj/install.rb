#! /usr/bin/env ruby

dirname, basename = File.split File.expand_path(__FILE__)

libidr = 'lib'
bindir = 'bin'
gem_home = 'gem_home'

rails_root = File.expand_path File.join(dirname, '../../../')
bj = File.join rails_root, 'script', 'bj'

gems = %w[ attributes arrayfields main systemu orderedhash bj ]

# in the plugin dir... 
Dir.chdir dirname do
  puts "in #{ dirname }..."

  # install gems locally
  puts "installing #{ gems.join ' ' }..."
  spawn "gem install #{ gems.join ' ' } --install-dir=#{ gem_home } --remote --force --include-dependencies --no-wrappers"
  puts "."

=begin
=end
  # copy libs over to libdir
  glob = File.join gem_home, "gems/*/lib/*"
  entries = Dir.glob glob
  entries.each do |entry|
    next if entry =~ %r/-\d+\.\d+\.\d+\.rb$/
    src, dst = entry, libidr
    puts "#{ src } -->> #{ dst }..."
    FileUtils.cp_r src, dst 
    puts "."
  end

  # copy bins over to bindir 
  glob = File.join gem_home, "gems/*/bin/*"
  entries = Dir.glob glob
  entries.each do |entry|
    next if entry =~ %r/-\d+\.\d+\.\d+\.rb$/
    src, dst = entry, bindir
    puts "#{ src } -->> #{ dst }..."
    FileUtils.cp_r src, dst 
    puts "."
  end

=begin
  # copy gem_home/bj-x.x.x/bin/bj to rails_root/script/bj
  glob = File.join gem_home, "gems/bj-*/bin/*"
  srcs = Dir.glob glob
  srcs.each do |src|
    basename = File.basename src
    dst = File.join rails_root, 'script', basename 
    puts "#{ src } -->> #{ dst }..."
    FileUtils.cp_r src, dst
    File.chmod 0755, dst
    puts "."
  end
=end

  # install bin/bj to script/bj
  src, dst = File.join(bindir, "bj"), File.join(rails_root, "script", "bj") 
  puts "#{ src } -->> #{ dst }..."
  FileUtils.cp src, dst
  File.chmod 0755, dst
  puts "."

  # kill all the local gems
  FileUtils.rm_rf gem_home

  # dump help
  puts("=" * 79)
  ruby = which_ruby
  system "#{ ruby } #{ bj.inspect } '--help'"
end



BEGIN {
  require 'fileutils'
  require 'rbconfig'

  def spawn command
    oe = `#{ command } 2>&1`
    raise "command <#{ command }> failed with <#{ $?.inspect }>" unless $?.exitstatus == 0
    oe
  end

  def which_ruby
    c = ::Config::CONFIG
    ruby = File::join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
    raise "ruby @ #{ ruby } not executable!?" unless test(?e, ruby)
    ruby
  end
}
