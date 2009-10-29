module ParallelTests
  extend self

  # finds all tests and partitions them into groups
  def tests_in_groups(root, num)
    specs_with_sizes = find_specs_with_sizes(root)
    
    groups = []
    current_group = current_size = 0
    specs_with_sizes.each do |spec, size|
      current_size += size
      # inserts into next group if current is full and we are not in the last group
      if current_size > group_size(specs_with_sizes, num) and num > current_group + 1
        current_size = 0
        current_group += 1
      end
      groups[current_group] ||= []
      groups[current_group] << spec
    end
    groups
  end

  def run_tests(test_files, process_number)
    require_list = test_files.map { |filename| "\"#{filename}\"" }.join(",")
    test_env_number = process_number == 0 ? '' : process_number + 1
    cmd = "export RAILS_ENV=test ; export TEST_ENV_NUMBER=#{test_env_number} ; ruby -Itest -e '[#{require_list}].each {|f| require f }'"

    execute_command(cmd)
  end

  def execute_command(cmd)
    f = open("|#{cmd}")
    all = ''
    while out = f.gets(".")#split by '.' because every test is a '.'
      all+=out
      print out
      STDOUT.flush
    end
    all
  end

  def find_results(test_output)
    test_output.split("\n").map {|line|
      line = line.gsub(/\.|F|\*/,'')
      next unless line =~ /\d+ example[s]?, \d+ failure[s]?, \d+ pending/
      line
    }.compact
  end

  def failed?(results)
    !! results.detect{|r| r=~ /[1-9] failure[s]?/}
  end

  private

  def self.group_size(specs_with_sizes, num_groups)
    total_size = specs_with_sizes.inject(0) { |sum, spec| sum += spec[1] }
    total_size / num_groups.to_f
  end

  def self.find_specs_with_sizes(root)
    specs = Dir["#{root}/test/**/*_test.rb"].sort
    specs.map { |spec| [ spec, File.stat(spec).size ] }
  end
end
