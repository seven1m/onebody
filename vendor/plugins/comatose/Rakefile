require 'rake'
require 'rake/tasklib'
require 'rake/testtask'
require 'rake/rdoctask'
require 'test/behaviors'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the Comatose plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Behaviors::ReportTask.new :specs do |t|
  t.pattern = 'test/**/*_test.rb'
end

desc 'Generate documentation for Comatose.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Comatose'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Builds the admin costumizable layout, the embedded layout have the JS and CSS inlined"
task :build do
  require 'erb'

  # Javascript
  script_path = File.join('resources', 'public', 'javascripts', 'comatose_admin.js')
  script_contents = ''
  # Stylesheet
  style_path = File.join('resources', 'public', 'stylesheets', 'comatose_admin.css')
  style_contents = ''
  # Layout Template
  tmpl_path = File.join('resources', 'layouts', 'comatose_admin_template.rhtml')
  tmpl_contents = ''
  # Layout Target
  layout_path = File.join('views', 'layouts', 'comatose_admin.rhtml')
  layout_contents = ''
  # Customizable Target
  customizable_path = File.join('views', 'layouts', 'comatose_admin_customize.rhtml')
  
  # Read the file contents...
  File.open(script_path, 'r') {|f| script_contents = "<script>\n#{f.read}\n</script>" }
  File.open(style_path, 'r')  {|f| style_contents = "<style>\n#{f.read}\n</style>" }
  File.open(tmpl_path, 'r')   {|f| tmpl_contents = f.read }

  # Create the final layout...
  layout_contents = ERB.new( tmpl_contents ).result(binding)
  
  # Write it out...
  File.open(layout_path, 'w') {|f| f.write layout_contents }
  
  # Now let's create the customizable one...
  style_contents = "<%= stylesheet_link_tag 'comatose_admin' %>"
  script_contents = "<%= javascript_include_tag 'comatose_admin' %>"
  
  # Create the final layout...
  layout_contents = ERB.new( tmpl_contents ).result(binding)
  
  # Write it out...
  File.open(customizable_path, 'w') {|f| f.write layout_contents }
  
  # That's it -- we're done.
  puts "Finished."
end

namespace :scm do

  desc "Adds missing files into SCM, interactively"
  task :add do
    scm_processor(:add)
  end

  desc "Reverts and Removes deleted files from SCM, interactively"
  task :remove do
    scm_processor(:remove)
  end

  desc "Looks for added files, then removed ones"
  task :add_remove do
    scm_processor(:add,    "No files to add")
    scm_processor(:remove, "No files to remove")    
  end

end

SVN = ENV['SVN'] || 'svk'

def propset(prop, value, *targets)
  sh %(#{SVN} propset #{prop} "#{value}" #{targets.join(' ')})
end

def add(dir)
  sh %(#{SVN} add #{dir})
end

def remove(file)
  sh %(#{SVN} revert #{file})
  sh %(#{SVN} delete #{file})
end

def stat
  `#{SVN} stat`
end

def project_name
  File.basename(File.expand_path(RAILS_ROOT))
end

def scm_processor(mode, no_targets_msg="Nothing to do")
  raise "Requires mode :add or :remove" if mode.nil? or ![:add,:remove].include?(mode)
  re = (mode == :add) ? [ /^\?/, /^\?\s*/ ] : [ /^\!/, /^\!\s*/ ]
  files = stat.select{ |e| re[0] =~ e}.collect{|e| e.sub(re[1], '').chomp }
  puts
  if files.length == 0
    puts no_targets_msg
  else
    files.map {|f| puts "  #{f}"}
    print "\n#{mode.to_s.capitalize} all of these? (y/n/i) : "
    affected_files = 0
    if STDIN.gets =~ /^(y|i)/i
      case $1.downcase
        when 'y'
          (mode == :add) ? add(files.join(' ')) : files.map { |f| remove(f) }
          affected_files = files.length
        when 'i'
          puts "\n[Interactive Mode]\n"
          files.each do |file|
            print "#{mode.to_s.capitalize} '#{file}'? (y/n) : "
            if /^y/i =~ STDIN.gets
              (mode == :add) ? add(file) : remove(file)
              affected_files += 1
            else
              puts "Ignored"
            end
          end
      end
    end
    puts "\n#{affected_files} file(s) affected, #{files.length - affected_files} ignored"
  end
  puts
end
