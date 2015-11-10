RSPEC_CMD = "bundle exec spring rspec --color --tty"

@last_test = nil

def run_tests(test, force=false)
  test = @last_test unless File.exist?(test) or force or not @last_test
  if force || File.exist?(test)
    @last_test = test
    puts "-" * 80
    rspec_cmd = "#{RSPEC_CMD} #{test}"
    puts rspec_cmd
    cmd = IO.popen("#{rspec_cmd} 2>&1")
    $stdout.write(cmd.getc) until cmd.eof?
  else
    puts "#{test} does not exist."
  end
end

def run_suite
  run_tests('spec', :force)
end

watch('^spec/.*_spec\.rb') { |m| run_tests(m.to_s) }
watch('^app/(.*)\.rb'    ) { |m| run_tests("spec/#{m[1]}_spec.rb") }
watch('^lib/(.*)\.rb'    ) { |m| run_tests("spec/lib/#{m[1]}_spec.rb") }

Signal.trap('QUIT') { run_suite } # Ctrl-\
