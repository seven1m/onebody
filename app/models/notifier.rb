class Notifier < ActionMailer::Base
  def profile_update(person, updates)
    recipients SEND_UPDATES_TO
    from SYSTEM_NOREPLY_EMAIL
    subject "Profile Update from #{person.name}."
    body :person => person, :updates => updates
  end
  
  def email_update(person)
    recipients SEND_UPDATES_TO
    from SYSTEM_NOREPLY_EMAIL
    subject "#{person.name} Changed Email"
    body :person => person
  end
  
  def message(to, msg)
    recipients to.email
    from msg.email_from
    if msg.group
      subject "#{msg.subject} [#{msg.group.name}]"
    elsif msg.wall
      subject 'Wall Post'
    else
      subject msg.subject
    end
    body :to => to, :msg => msg
  end
  
  def email_verification(verification)
    recipients verification.email
    from SYSTEM_NOREPLY_EMAIL
    subject "Verify Email"
    body :verification => verification
  end
  
  def mobile_verification(verification)
    recipients verification.email
    from SYSTEM_NOREPLY_EMAIL
    subject "Verify Mobile"
    body :verification => verification
  end
  
  def birthday_verification(params, verification)
    recipients BIRTHDAY_VERIFICATION_EMAIL
    from verification.email
    subject "Birthday Verification"
    params[:verification] = verification
    body params
  end
  
  def receive(email)
    if person = Person.find_by_email(email.from)
      email.to.each do |address|
        if group = Group.find_by_address(address.downcase) and group.can_send? person
          message = Message.create(
            :group => group,
            :person => person,
            :subject => email.subject,
            :body => email.body
          )
        end
      end
    end
  end
end
