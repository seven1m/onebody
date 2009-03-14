class Notifier < ActionMailer::Base
  helper :notifier

  def profile_update(person, updates)
    recipients Setting.get(:contact, :send_updates_to)
    from Site.current.noreply_email
    subject "Profile Update from #{person.name}."
    body :person => person, :updates => updates
  end
  
  def email_update(person)
    recipients Setting.get(:contact, :send_email_changes_to)
    from Site.current.noreply_email
    subject "#{person.name} Changed Email"
    body :person => person
  end
  
  def date_and_time_report
    recipients Setting.get(:contact, :tech_support_email)
    from Site.current.noreply_email
    subject "Date & Time Incorrect"
  end
  
  def friend_request(person, friend)
    recipients "#{friend.name} <#{friend.email}>"
    from Site.current.noreply_email
    subject "Friend Request from #{person.name}"
    body :person => person, :friend => friend
  end
  
  def membership_request(group, person)
    unless (to = group.admins.select { |p| p.email.to_s.any? }.map { |p| "#{p.name} <#{p.email}>" }).any?
      unless (to = Admin.find_all_by_manage_updates(true).map { |a| "#{a.person.name} <#{a.person.email}>" }).any?
        to = Setting.get(:access, :super_admins)
      end
    end
    recipients to
    from person.email.to_s.any? ? "#{person.name} <#{person.email}>" : Site.current.noreply_email
    subject "Request to Join Group from #{person.name}"
    body :person => person, :group => group
  end
  
  def message(to, msg, id_and_code=nil)
    recipients to.email
    from msg.email_from(to)
    h = {'Reply-To' => msg.email_reply_to(to)}
    if msg.group
      h.update(
        'List-ID' => "#{msg.group.name} group on #{Setting.get(:name, :site)} <#{msg.group.address}.#{URI.parse(Setting.get(:url, :site)).host}>",
        'List-Help' => "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>",
        'List-Unsubscribe' => "<#{Setting.get(:url, :site)}groups/toggle_email/#{msg.group.id}?person_id=#{to.id}&code=#{msg.group.get_options_for(to, true).code}>",
        'List-Post' => (msg.group.can_post?(to) ? "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>" : 'NO (you are not allowed to post to this list)'),
        'List-Archive' => "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>"
      ) unless to.new_record? # allows preview to work
      if msg.group.leader
        h.update 'List-Owner' => "<#{Setting.get(:url, :site)}>people/view/#{msg.person.id}> (#{msg.person.name})"
      end
      if msg.group.address.to_s.any? and msg.group.can_post?(msg.person)
        h.update 'CC' => "\"#{msg.group.name}\" <#{msg.group.address + '@' + Site.current.host}>"
      end
    end
    headers h
    if msg.wall
      subject 'Wall Post'
    else
      subject msg.subject
    end
    part :content_type => "multipart/alternative" do |p|
      p.part :content_type => "text/plain", :body => render_message('message', :to => to, :msg => msg, :id_and_code => id_and_code)
    end
    msg.attachments.each do |a|
      attachment :content_type => a.content_type, :filename => a.name, :body => File.read(a.file_path)
    end
  end

  def simple_message(t, s, b, f=Site.current.noreply_email)
    recipients t
    from f
    subject s
    body b
  end

  def prayer_reminder(person, times)
    recipients person.email
    from Site.current.noreply_email
    subject "24-7 Prayer: Don't Forget!"
    body :times => times
  end
  
  def email_verification(verification)
    recipients verification.email
    from Site.current.noreply_email
    subject "Verify Email"
    body :verification => verification
  end
  
  def mobile_verification(verification)
    recipients verification.email
    from Site.current.noreply_email
    subject "Verify Mobile"
    body :verification => verification
  end
  
  def birthday_verification(params)
    recipients Setting.get(:contact, :birthday_verification_email)
    from params[:email]
    subject "Birthday Verification"
    body params
  end
  
  def pending_sign_up(person)
    recipients Setting.get(:features, :sign_up_approval_email)
    from Site.current.noreply_email
    subject "Pending Sign Up"
    body :person => person
  end
  
  def printed_directory(person, file)
    recipients "#{person.name} <#{person.email}>"
    from Site.current.noreply_email
    subject "#{Setting.get(:name, :site)} Directory"
    body :person => person
    attachment :content_type => 'application/pdf', :filename => 'directory.pdf', :body => file.read
  end
  
  def receive(email)
    sent_to = email.cc.to_a + email.to.to_a
    
    return unless email.from.to_s.any?
    return if sent_to.detect { |a| a =~ /no\-?reply|postmaster|mailer\-daemon/i }
    return if email.from.to_s =~ /no\-?reply|postmaster|mailer\-daemon/i
    return if email.subject =~ /^undelivered mail returned to sender|^returned mail/i
    return unless get_site(email)
    
    unless @person = get_from_person(email)
      Notifier.deliver_simple_message(
        email.from,
        'Message Rejected',
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the system does not recognize your email address " +
        "as a user of the system. If you want to send a message to someone, please send from " +
        "your registered account email address or sign in at #{Setting.get(:url, :site)} and " +
        "send your message via the Web."
      )
      return
    end
    
    unless body = get_body(email)
      Notifier.deliver_simple_message(
        email.from,
        'Message Unreadable',
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the #{Setting.get(:name, :site)} site cannot read " +
        "the message because it is not formatted as plain text nor does it have a plain text part. " +
        "Please set your email client to plain text (turn off Rich Text or HTML formatting), " +
        "or you may send your message directly from the site after signing into " +
        "#{Setting.get(:url, :site)}. If you continue to have trouble, please contact " +
        "#{Setting.get(:contact, :tech_support_contact)}."
      )
      return
    end

    @message_sent_to_group = false
    
    sent_to.each do |address|
      address, domain = address.strip.downcase.split('@')
      next unless address.any? and domain.any?
      next unless [Site.current.host, Site.current.secondary_host].compact.include?(domain)
      if group = Group.find_by_address(address) and group.can_send?(@person)
        group_email(group, email, body)
      elsif address.to_s.any? and not @message_sent_to_group # reply to previous message
        reply_email(email, body)
      end
    end
  end
  
  private
  
    def group_email(group, email, body)
      # if is this looks like a reply, try to link this message to its original based on the subject
      if email.subject =~ /^re:/i
        parent = group.messages.find_by_subject(email.subject.sub(/^re:\s?/i, ''), :order => 'id desc')
      else
        parent = nil
      end
      message = Message.create(
        :group => group,
        :parent => parent,
        :person => @person,
        :subject => email.subject,
        :body => clean_body(body),
        :dont_send => true
      )
      if message.errors.any?
        if message.errors.on_base != 'already saved' and message.errors.on_base != 'autoreply'
          Notifier.message_error_notification(email, message)
        end
      else
        if email.has_attachments?
          email.attachments.each do |attachment|
            name = File.split(attachment.original_filename.to_s).last
            unless ATTACHMENTS_TO_IGNORE.include? name.downcase
              att = message.attachments.create(
                :name => name,
                :content_type => attachment.content_type.strip
              )
              att.file = attachment
            end
          end
        end
        message.send_to_group(already_sent_to=email.to.to_a)
        @message_sent_to_group = true
      end
    end
    
    def reply_email(email, body)
      message, code_hash = get_in_reply_to_message_and_code(email)
      if message and message.code_hash == code_hash
        if message.created_at < (DateTime.now - MAX_DAYS_FOR_REPLIES)
          Notifier.deliver_simple_message(
            email.from,
            'Message Too Old',
            "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
            "Sorry for the inconvenience, but the message to which you're replying is too old. " +
            "This is to prevent unsolicited email to our users. If you wish to send a message " +
            "to this person, please sign into #{Setting.get(:url, :site)} and send the message " +
            "via the web site. If you need help, please contact " +
            "#{Setting.get(:contact, :tech_support_contact)}."
          )
        else
          to_person = message.person
          message = Message.create(
            :to => to_person,
            :person => @person,
            :subject => email.subject,
            :body => clean_body(body),
            :parent => message
          )
          if message.errors.any? and message.errors.on_base != 'already saved' and message.errors.on_base != 'autoreply'
            Notifier.message_error_notification(email, message)
          end
        end
      else
        # notify the sender that the message is unsolicited and was not delivered
        Notifier.deliver_simple_message(
          email.from,
          'Message Rejected',
          "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
          "Sorry for the inconvenience, but it appears the message was unsolicited. " +
          "If you want to send a message to someone, please sign in at #{Setting.get(:url, :site)}, " +
          "find the person, and click \"private message.\""
        )
      end
    end
    
    def get_in_reply_to_message_and_code(email)
      message_id, code_hash, message = nil
      # first try in-reply-to and references headers
      (email.in_reply_to.to_a + email.references.to_a).each do |in_reply_to|
        message_id, code_hash = (m = in_reply_to.match(/<(\d+)_([0-9abcdef]{6,6})_/)) && m[1..2]
        if message = Message.find_by_id(message_id)
          return [message, code_hash]
        end
      end
      # fallback to using id and code hash inside email body
      # (Outlook does not use the psuedo-standard headers we rely on above)
      message_id, code_hash = (m = get_body(email).match(/id:\s*(\d+)_([0-9abcdef]{6,6})/i)) && m[1..2]
      if message = Message.find_by_id(message_id)
        return [message, code_hash]
      end
    end
    
    def message_error_notification(email, message)
      Notifier.deliver_simple_message(
        email.from,
        'Message Error',
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the #{Setting.get(:name, :site)} site had " +
        "trouble saving the message (#{message.errors.full_messages.join('; ')}). " + 
        "You may post your message directly from the site after signing into " +
        "#{Setting.get(:url, :site)}. If you continue to have trouble, please contact " +
        "#{Setting.get(:contact, :tech_support_contact)}."
      )
    end
  
    def get_site(email)
      (email.cc.to_a + email.to.to_a).each do |address|
        return Site.current if Site.current = Site.find_by_host(address.downcase.split('@').last)
      end
      nil
    end
    
    def get_from_person(email)
      people = Person.find :all, :conditions => ["#{sql_lcase('email')} = ?", email.from.to_s.downcase]
      if people.length == 0
        # user is not found in the system, try alternate email
        Person.find :first, :conditions => ["#{sql_lcase('alternate_email')} = ?", email.from.to_s.downcase]
      elsif people.length == 1
        people.first
      elsif people.length > 1
        # try to narrow it down based on name in the from line
        people.detect do |p|
          p.name.downcase.split.first == email.friendly_from.to_s.downcase.split.first
        end
      end
    end
  
    def get_body(email)
      # if the message is multipart, try to grab the plain text part
      if email.multipart?
        email.parts.each do |part|
          return part.body if part.content_type.downcase == 'text/plain'
          if part.content_type.downcase == 'multipart/alternative'
            if sub_part = part.parts.select { |p| p.content_type.downcase == 'text/plain' }.first
              return sub_part.body
            end
          end
        end
      else
        return email.body
      end
    end
  
    def clean_body(body)
      # this has the potential for error, but we'll just go with it and see
      body.split(/^[>\s]*\- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \-/).first.strip
    end
end
