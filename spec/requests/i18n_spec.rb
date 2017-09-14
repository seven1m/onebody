require 'rails_helper'
require Rails.root.join('lib/i18n_scanner')

describe 'i18n', type: :request do
  include RSpec::Matchers

  it "doesn't have any missing keys" do
    I18nScanner.new.scan do |view, args|
      unless be_valid_i18n.matches?(args)
        puts "Could not find key #{args.inspect} (referenced in file #{view})"
      end
      expect(args).to(be_valid_i18n)
    end
  end
end
