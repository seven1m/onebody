LINUX = RUBY_PLATFORM =~ /linux/i unless defined?(LINUX)

def escape(arg)
  arg.gsub(/\e\[..m?/, '')         # rid us of ansi escape sequences
     .gsub(/["`]/, "'")
     .gsub(/\r?\n/, "\\\\\\\\\\n")
end

def notify(pass, heading, body='')
  cmd = if LINUX
    %(notify-send --hint=int:transient:1 "#{escape heading}" "#{escape body[0..400]}")
  else
    if pass
      icon = ''
    else
      icon = '-contentImage /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns'
    end
    %(terminal-notifier -message "#{escape body}" -title "#{escape heading}" #{icon})
  end
  system(cmd)
end

@last_test = nil

def run_specs(test, force=false)
  unless File.exist?(test) or force or not @last_test
    test = @last_test
  end

  if force || File.exist?(test)
    @last_test = test
    puts "-" * 80
    rspec_cmd = "spring rspec --color --tty"
    puts "#{rspec_cmd} #{test}"
    cmd = IO.popen("#{rspec_cmd} #{test} 2>&1")
    result = ''
    until cmd.eof?
      char = cmd.getc
      result << char
      $stdout.write(char)
    end
    if result =~/.*0 failures/
      summary = $~.to_s
      secs = result.match(/Finished in ([\d\.]+)/)[1]
      notify(true, 'Test Success', summary + ' ' + secs)
    elsif result =~ /(\d+) failures?/
      summary = $~.to_s
      notify(false, 'Test Failure', summary)
    else
      notify(false, 'Test Error', 'One or more tests could not run due to error.')
    end
  else
    puts "#{test} does not exist."
  end
end

def run_suite
  run_specs('test/*', :force)
end

watch('^spec/(.*)_spec\.rb'      ) { |m| run_specs("spec/#{m[1]}_spec.rb")                    }
watch('^spec/factories/(.*)\.rb' ) { |m| run_specs("spec/models/#{m[1]}_spec.rb")             }
watch('^app/models/(.*)\.rb'     ) { |m| run_specs("spec/models/#{m[1]}_spec.rb")             }
watch('^app/presenters/(.*)\.rb' ) { |m| run_specs("spec/presenters/#{m[1]}_spec.rb")         }
watch('^app/authorizers/(.*)\.rb') { |m| run_specs("spec/models/authorizers/#{m[1]}_spec.rb") }
watch('^app/concerns/(.*)\.rb'   ) { |m| run_specs("spec/models/concerns/#{m[1]}_spec.rb")    }
watch('^app/controllers/(.*)\.rb') { |m| run_specs("spec/controllers/#{m[1]}_spec.rb")        }
watch('^app/helpers/(.*)\.rb'    ) { |m| run_specs("spec/helpers/#{m[1]}_spec.rb")            }
watch('^app/jobs/(.*)\.rb'       ) { |m| run_specs("spec/jobs/#{m[1]}_spec.rb")               }
watch('^config/locales/.*'       ) { |m| run_specs("spec/requests/i18n_spec.rb")              }
watch('^lib/(.*)\.rb'            ) { |m| run_specs("spec/lib/#{m[1]}_spec.rb")                }

@interrupt_received = false

# ^C
#Signal.trap 'INT' do
#  if @interrupt_received
#    exit 0
#  else
#    @interrupt_received = true
#    puts "\nInterrupt a second time to quit"
#    Kernel.sleep 1
#    @interrupt_received = false
#    run_suite
#  end
#end
