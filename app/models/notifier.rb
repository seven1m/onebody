class Notifier < ActionMailer::Base
  helper :notifier, :application

  default from: -> _ { Site.current.noreply_email }, charset: 'UTF-8'

  def profile_update(person, updates)
    @person = person
    @updates = updates
    mail(
      to:      Setting.get(:contact, :send_updates_to),
      subject: "Profile Update from #{person.name}."
    )
  end

  def email_update(person)
    @person = person
    mail(
      to:      Setting.get(:contact, :send_email_changes_to),
      subject: "#{person.name} Changed Email"
    )
  end

  def date_and_time_report
    mail(
      to:      Setting.get(:contact, :tech_support_email),
      subject: "Date & Time Incorrect"
    )
  end

  def friend_request(person, friend)
    @person = person
    @friend = friend
    mail(
      to:      "\"#{friend.name}\" <#{friend.email}>",
      subject: "Friend Request from #{person.name}"
    )
  end

  def membership_request(group, person)
    @group = group
    @person = person
    unless (to = group.admins.select { |p| p.email.to_s.any? }.map { |p| "#{p.name} <#{p.email}>" }).any?
      unless (to = Admin.to_a.select { |a| a.manage_updates? }.map { |a| "#{a.person.name} <#{a.person.email}>" }).any?
        to = Admin.where(super_admin: true).map { |a| a.person.email }
      end
    end
    mail(
      to:      to,
      from:    person.email.to_s.any? ? "\"#{person.name}\" <#{person.email}>" : Site.current.noreply_email,
      subject: "Request to Join Group from #{person.name}"
    )
  end

  def full_message(to, msg, id_and_code=nil)
    @to          = to
    @msg         = msg
    @id_and_code = id_and_code
    h = {'Reply-To' => msg.email_reply_to(to)}
    if msg.group
      h.update(
        'List-ID' => "#{msg.group.name} group on #{Setting.get(:name, :site)} <#{msg.group.address}.#{URI.parse(Setting.get(:url, :site)).host}>",
        'List-Help' => "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>",
        'List-Unsubscribe' => msg.disable_group_email_link(to),
        'List-Post' => (msg.group.can_post?(to) ? "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>" : 'NO (you are not allowed to post to this list)'),
        'List-Archive' => "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>"
      ) unless to.new_record? # allows preview to work
      if msg.group.address.to_s.any? and msg.group.can_post?(msg.person)
        h.update 'CC' => "\"#{msg.group.name}\" <#{msg.group.address + '@' + Site.current.host}>"
      end
    end
    headers h
    msg.attachments.each do |a|
      #attachments[a.name] = {
        #:mime_type => a.content_type,
        #:content   => File.read(a.file.path)
      #}
      # TODO check that it's ok to not specify content-type...
      attachments[a.name] = File.read(a.file.path)
    end
    mail(
      to:      to.email,
      from:    msg.email_from(to),
      subject: msg.subject
    ) do |format|
      if msg.body.to_s.any?
        format.text
      end
      if msg.html_body.to_s.any?
        format.html
      end
    end
  end

  # used for auto-generated responses
  def simple_message(t, s, b, f=nil)
    headers 'Auto-Submitted' => 'auto-replied'
    mail(
      to:      t,
      from:    f || Site.current.noreply_email,
      subject: s
    ) do |format|
      format.text { render text: b }
    end
  end

  def prayer_reminder(person, times)
    @times = times
    mail(
      to:      person.email,
      subject: "24-7 Prayer: Don't Forget!"
    )
  end

  def email_verification(verification)
    @verification = verification
    mail(
      to:      verification.email,
      subject: "Verify Email"
    )
  end

  def mobile_verification(verification)
    @verification = verification
    mail(
      to:      verification.email,
      subject: "Verify Mobile"
    )
  end

  def birthday_verification(name, email, phone, birthday, notes)
    @name     = name
    @email    = email
    @phone    = phone
    @birthday = birthday
    @notes    = notes
    mail(
      to:      Setting.get(:contact, :birthday_verification_email),
      from:    email,
      subject: "Birthday Verification"
    )
  end

  def pending_sign_up(person)
    @person = person
    mail(
      to:      Setting.get(:features, :sign_up_approval_email),
      subject: "Pending Sign Up"
    )
  end

  def printed_directory(person, file)
    @person = person
    # TODO check that it is ok that we don't specify content-type application/pdf here
    attachments['directory.pdf'] = file.read
    mail(
      to:      "\"#{person.name}\" <#{person.email}>",
      subject: "#{Setting.get(:name, :site)} Directory"
    )
  end

  def receive(email)
    sent_to = Array(email.cc) + Array(email.to) # has to be reversed (cc first) so that group replies work right

    return unless email.from.to_s.any?
    return if email['Auto-Submitted'] and not %w(false no).include?(email['Auto-Submitted'].to_s.downcase)
    return if email['Return-Path'] and ['<>', ''].include?(email['Return-Path'].to_s)
    return if sent_to.detect { |a| a =~ /no\-?reply|postmaster|mailer\-daemon/i }
    return if email.from.to_s =~ /no\-?reply|postmaster|mailer\-daemon/i
    return if email.subject =~ /^undelivered mail returned to sender|^returned mail|^delivery failure/i
    return if email.message_id =~ Message::MESSAGE_ID_RE and m = Message.unscoped { Message.where(id: $1).first } and m.code_hash == $2 # just sent, looping back into the receiver
    return if ProcessedMessage.where(header_message_id: email.message_id).first
    return unless get_site(email)

    unless @person = get_from_person(email)
      if @multiple_people_with_same_email
        reject_msg = \
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the system cannot determine who you are because more " +
        "than one person in your family share the same email address. You can fix this by " +
        "configuring your own personal email address in the system, or by setting the sender name " +
        "in your email account to be the same as your name in our database. " +
        "Alternatively, you can sign in at #{Setting.get(:url, :site)} and " +
        "send your message via the Web."
      else
        reject_msg = \
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the system does not recognize your email address " +
        "as a user of the system. If you want to send a message to someone, please send from " +
        "your registered account email address or sign in at #{Setting.get(:url, :site)} and " +
        "send your message via the Web."
      end
      if return_to = email['Return-Path'] ? email['Return-Path'].to_s : email.from
        Notifier.simple_message(
          return_to,
          "Message Rejected: #{email.subject}",
          reject_msg
        ).deliver
      end
      return
    end

    unless body = get_body(email) and (body[:text] or body[:html])
      Notifier.simple_message(
        email['Return-Path'] ? email['Return-Path'].to_s : email.from,
        "Message Unreadable: #{email.subject}",
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but the #{Setting.get(:name, :site)} site cannot read " +
        "the message because it is not formatted as either plain text or HTML. " +
        "Please set your email client to plain text (turn off Rich Text), " +
        "or you may send your message directly from the site after signing into " +
        "#{Setting.get(:url, :site)}. If you continue to have trouble, please contact " +
        "#{Setting.get(:contact, :tech_support_contact)}."
      ).deliver
      return
    end

    @message_sent_to_group = false
    sent_to_count = 0

    sent_to.each do |address|
      address, domain = address.strip.downcase.split('@')
      next unless address.any? and domain.any?
      our_domain = [Site.current.host, Site.current.secondary_host].compact.include?(domain)
      if our_domain and group = Group.where(address: address).first and group.can_send?(@person)
        message = group_email(group, email, body)
        if @message_sent_to_group
          sent_to_count += 1
        elsif !message.valid? and message.errors[:base] !~ /already saved|autoreply/
          Notifier.simple_message(
            email['Return-Path'] ? email['Return-Path'].to_s : email.from,
            "Message Error: #{email.subject}",
            "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
            "Sorry for the inconvenience, but the #{Setting.get(:name, :site)} site had " +
            "trouble saving the message (#{message.errors.full_messages.join('; ')}). " +
            "You may post your message directly from the site after signing into " +
            "#{Setting.get(:url, :site)}. If you continue to have trouble, please contact " +
            "#{Setting.get(:contact, :tech_support_contact)}."
          ).deliver
          sent_to_count += 1
          break
        end
      elsif address.to_s.any? and not @message_sent_to_group # reply to previous message
        result = reply_email(email, body)
        sent_to_count += 1 if result
      end
    end

    if sent_to_count == 0 and return_to = email['Return-Path'] ? email['Return-Path'].to_s : email.from
      # notify the sender that no mail was sent
      Notifier.simple_message(
        return_to,
        "Message Rejected: #{email.subject}",
        "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
        "Sorry for the inconvenience, but it appears the message was not properly addressed. " +
        "If you want to send a message to someone, please sign in at #{Setting.get(:url, :site)}, " +
        "find the person, and click \"Send Email.\""
      ).deliver
    end

    # do not process this one ever again
    ProcessedMessage.create(
      header_message_id: email.message_id
    )

  end

  private

    def group_email(group, email, body)
      # if is this looks like a reply, try to link this message to its original based on the subject
      if email.subject =~ /^re:/i
        parent = group.messages.where(subject: email.subject.sub(/^re:\s?/i, '')).order('id desc').first
      else
        parent = nil
      end
      message = Message.create(
        group: group,
        parent: parent,
        person: @person,
        subject: email.subject,
        body: clean_body(body[:text]),
        html_body: clean_body(body[:html]),
        dont_send: true
      )
      if message.valid?
        if email.has_attachments?
          email.attachments.each do |attachment|
            name = File.split(attachment.filename.to_s).last
            unless ATTACHMENTS_TO_IGNORE.include? name.downcase
              message.attachments.create(
                name:         name,
                content_type: attachment.content_type.strip,
                file:         FakeFile.new(attachment.body.to_s, name)
              )
            end
          end
        end
        already_sent_to = email.to.to_a
        message.send_to_group(already_sent_to)
        @message_sent_to_group = true
      end
      message
    end

    def reply_email(email, body)
      message, code_hash = get_in_reply_to_message_and_code(email)
      if message and message.code_hash == code_hash
        if message.created_at < (DateTime.now - MAX_DAYS_FOR_REPLIES)
          Notifier.simple_message(
            email['Return-Path'] ? email['Return-Path'].to_s : email.from,
            "Message Too Old: #{email.subject}",
            "Your message with subject \"#{email.subject}\" was not delivered.\n\n" +
            "Sorry for the inconvenience, but the message to which you're replying is too old. " +
            "This is to prevent unsolicited email to our users. If you wish to send a message " +
            "to this person, please sign into #{Setting.get(:url, :site)} and send the message " +
            "via the web site. If you need help, please contact " +
            "#{Setting.get(:contact, :tech_support_contact)}."
          ).deliver
          false
        else
          to_person = message.person
          message = Message.create(
            to: to_person,
            person: @person,
            subject: email.subject,
            body: clean_body(body[:text]),
            html_body: clean_body(body[:html]),
            parent: message
          )
          true
        end
      end
    end

    def get_in_reply_to_message_and_code(email)
      message_id, code_hash, message = nil
      # first try in-reply-to and references headers
      (Array(email.in_reply_to) + Array(email.references)).each do |in_reply_to|
        message_id, code_hash = (m = in_reply_to.match(Message::MESSAGE_ID_RE)) && m[1..2]
        if message = Message.where(id: message_id).first
          return [message, code_hash]
        end
      end
      # fallback to using id and code hash inside email body
      # (Outlook does not use the psuedo-standard headers we rely on above)
      message_id, code_hash = (m = get_body(email).to_s.match(Message::MESSAGE_ID_RE_IN_BODY)) && m[1..2]
      if message = Message.where(id: message_id).first
        return [message, code_hash]
      end
    end

    def get_site(email)
      # prefer the to address
      (Array(email.cc) + Array(email.to)).each do |address|
        return Site.current if Site.current = Site.where(host: address.downcase.split("@").last).first
      end
      # fallback if to address was rewritten
      # Calvin College in MI is known to rewrite our from/reply-to addresses to be the same as the host that made the connection
      if get_body(email).to_s =~ Message::MESSAGE_ID_RE_IN_BODY
        Site.each do
          return Site.current if get_in_reply_to_message_and_code(email)
        end
      end
      nil
    end

    def get_from_person(email)
      people = Person.where("lcase(email) = ?", email.from.first.downcase).to_a
      if people.length == 0
        # user is not found in the system, try alternate email
        Person.where("lcase(alternate_email) = ?", email.from.to_s.downcase).first
      elsif people.length == 1
        people.first
      elsif people.length > 1
        @multiple_people_with_same_email = true
        # try to narrow it down based on name in the from line
        people.detect do |p|
          p.name.downcase.split.first == email.header['from'].value.to_s.downcase.split.first
        end
      end
    end

    def get_body(email)
      self.class.get_body(email)
    end

    def self.get_body(email)
      # if the message is multipart, try to grab the plain text and/or html parts
      text = nil
      html = nil
      if email.multipart?
        email.parts.each do |part|
          case part.content_type.downcase.split(';').first
            when 'text/plain'
              text = part.body.to_s
            when 'text/html'
              html = part.body.to_s
            when 'multipart/alternative'
              if p = part.parts.detect { |p| p.content_type.downcase.split(';').first == 'text/plain' }
                text ||= p.body.to_s
              end
              if p = part.parts.detect { |p| p.content_type.downcase.split(';').first == 'text/html'  }
                html ||= p.body.to_s
              end
          end
        end
        return {text: text, html: html}
      elsif email.content_type.downcase.split(';').first == 'text/html'
        return {text: nil, html: email.body.to_s}
      else
        return {text: email.body.to_s}
      end
    end

    def clean_body(body)
      # this has the potential for error, but we'll just go with it and see
      body.to_s.split(/^[>\s]*\- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \-/).first.to_s.strip
    end
end
