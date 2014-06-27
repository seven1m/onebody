require 'rspec/expectations'

RSpec::Matchers.define :be_valid_i18n do
  match do |key|
    begin
      I18n.t(*key)
    rescue I18n::MissingTranslationData
      false
    end
  end

  failure_message do |actual|
    "expected that #{actual.inspect} would be a valid i18n key"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual.inspect} would not be a valid i18n key"
  end
end
