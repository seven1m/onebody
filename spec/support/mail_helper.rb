module MailHelper
  def assert_deliveries(count)
    expect(ActionMailer::Base.deliveries.length).to eq(count)
  end

  def assert_emails_delivered(email, people)
    people.each do |person|
      matches = ActionMailer::Base.deliveries.select do |delivered|
        delivered.subject == email.subject and \
        delivered.body.to_s.index(email.body.to_s) and \
        delivered.to == [person.email]
      end
      expect(matches.length).to eq(1)
    end
  end
end
