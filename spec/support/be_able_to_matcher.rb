require 'rspec/expectations'

RSpec::Matchers.define :be_able_to do |action, subject|
  match do |user|
    user.send("can_#{action}?", subject)
  end

  failure_message do |actual|
    "expected that #{actual.inspect} would be able to #{action} #{subject.inspect}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual.inspect} would not be able to #{action} #{subject.inspect}"
  end
end
