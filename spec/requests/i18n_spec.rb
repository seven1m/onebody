require_relative '../spec_helper'

describe 'i18n' do

  include RSpec::Matchers

  it "doesn't have any missing keys" do
    dirs = ['app/views/**/*', 'app/controllers/**/*'].map { |p| Rails.root.join(p) }
    Dir[*dirs].each do |view|
      next if File.directory?(view)
      path = view[Rails.root.join("app/views").to_s.length+1..-1]
      namespace = path.sub(/\..+$/, '').gsub(/\//, '.')
      content = File.read(view).split(/\n/).reject { |l| l =~ /#\s*notest\s*$/ }.join("\n")
      content.scan(/(?:^|\W)t\((.+?)\)/).each do |(args)|
        key = args.match(/['"](.+?)['"]/)[1]
        key = namespace + key if key.start_with?('.')
        scope = args.match(/scope: ['"](.+?)['"]/).try(:[], 1)
        args = [key]
        args << { scope: scope } if scope
        unless be_valid_i18n.matches?(args)
          puts "Could not find key #{args.inspect} (referenced in file #{view})"
        end
        expect(args).to(be_valid_i18n)
      end
    end
  end

end
