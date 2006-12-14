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
    if msg.wall
      subject 'Wall Post'
    else
      subject msg.subject
    end
    body :to => to, :msg => msg
  end

  def simple_message(to, s, b)
    recipients to
    from SYSTEM_NOREPLY_EMAIL
    subject s
    body b
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
        address = address.downcase.split('@').first.to_s.strip
        if address.any? and group = Group.find_by_address(address) and group.can_send? person
          if email.subject =~ /^re:/i
            parent = group.messages.find_by_subject(email.subject.gsub(/^re:\s?/i, ''), :order => 'id desc')
          else
            parent = nil
          end
          message = Message.create(
            :group => group,
            :parent => parent,
            :person => person,
            :subject => email.subject,
            :body => email.body
          )
        end
      end
    else
      Notifier.deliver_simple_message(email.from, 'User Unknown', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{SITE_TITLE} site cannot determine who you are based on your email address. Please send email from the address we have in the system for you. If you continue to have trouble, please contact #{TECH_SUPPORT_CONTACT}.")
    end
  end
end
