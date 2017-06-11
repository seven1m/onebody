module MailHelper
  def assert_deliveries(count)
    expect(ActionMailer::Base.deliveries.length).to eq(count)
  end

  def assert_emails_delivered(email, people)
    people.each do |person|
      matches = ActionMailer::Base.deliveries.select do |delivered|
        delivered.subject == email.subject && \
          delivered.body.to_s.index(email.body.to_s) && \
          delivered.to == [person.email]
      end
      expect(matches.length).to eq(1)
    end
  end

  def delivered_emails_as_hashes
    ActionMailer::Base.deliveries.map do |mail|
      {
        from:    mail.from,
        to:      mail.to,
        subject: mail.subject,
        body:    Notifier.get_body(mail)[:text]
      }
    end
  end
end
