SEED_OPTIONS = ENV['SEED'] ? "--seed #{ENV['SEED']}" : ''
RSPEC_CMD = "bundle exec spring rspec --color --tty #{SEED_OPTIONS}"

@last_test = nil

def run_tests(test, force=false)
  if (ft = focused_tests).any?
    puts "Running focused test(s)..."
    test = ft.join(' ')
  end
  test = @last_test unless File.exist?(test) or force or not @last_test
  if force || File.exist?(test)
    @last_test = test
    puts "-" * 80
    rspec_cmd = "#{RSPEC_CMD} #{format_options} #{test}"
    puts test
    cmd = IO.popen("#{rspec_cmd} 2>&1")
    $stdout.write(cmd.getc) until cmd.eof?
  else
    puts "#{test} does not exist."
  end
end

def run_suite
  run_tests('spec', :force)
end

def focused_tests
  Dir['spec/**/*_spec.rb'].to_a.select { |f| File.read(f).match(/focus: true|fdescribe|fcontext|fit ['"]/) }
end

def binding_pry
  system("grep --include *.rb -r \"binding\\.pry\" * &>/dev/null")
end

def format_options
  return '' if binding_pry
  '--format progress'
end

watch('^spec/.*_spec\.rb'   ) { |m| run_tests(m.to_s) }
watch('^app/(.*)\.rb'       ) { |m| run_tests("spec/#{m[1]}_spec.rb") }
watch('^lib/(.*)\.(rb|rake)') { |m| run_tests("spec/lib/#{m[1]}_spec.rb") }

Signal.trap('QUIT') { run_suite } # Ctrl-\
