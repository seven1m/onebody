class Notifier < ActionMailer::Base
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
  
  def message(to, msg)
    recipients to.email
    from msg.email_from(to)
    h = {'Reply-To' => msg.email_reply_to(to)}
    if msg.group
      h.update(
        'List-ID' => "#{msg.group.name} group on #{Setting.get(:name, :site)} <#{msg.group.address}.#{Setting.get(:url, :site)}>",
        'List-Help' => "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>",
        'List-Unsubscribe' => "<#{Setting.get(:url, :site)}groups/toggle_email/#{msg.group.id}?person_id=#{to.id}&code=#{msg.group.get_options_for(to, true).code}>",
        'List-Post' => (msg.group.can_post?(to) ? "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>" : 'NO (you are not allowed to post to this list)'),
        'List-Archive' => "<#{Setting.get(:url, :site)}groups/view/#{msg.group.id}>"
      )
      if msg.group.leader
        h.update 'List-Owner' => "<#{Setting.get(:url, :site)}>people/view/#{msg.person.id}> (#{msg.person.name})"
      end
      #if GROUP_LEADER_EMAIL and GROUP_LEADER_NAME
      #  h.update 'List-Owner' => "<mailto:#{GROUP_LEADER_EMAIL}> (#{GROUP_LEADER_NAME})"
      #end
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
    body :to => to, :msg => msg
    msg.attachments.each do |a|
      attachment :content_type => a.content_type, :filename => a.name, :body => a.file
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
  
  # TODO: This is probably the ugliest bit of code in the whole app.
  def receive(email)
    return unless email.from.to_s.any?
    return if email.body.to_s =~ /mailboy-test/ # to protect people who don't know we upgraded
    person = nil
    (email.cc.to_a + email.to.to_a).each do |address|
      if site = Site.find_by_host(address.downcase.split('@').last)
        Site.current = site
        break
      end
    end
    return unless Site.current
    people = Person.find :all, :conditions => ["#{sql_lcase('email')} = ?", email.from.to_s.downcase]
    if people.length == 0
      # user is not found in the system, try alternate email
      person = Person.find :first, :conditions => ["#{sql_lcase('alternate_email')} = ?", email.from.to_s.downcase]
    elsif people.length == 1
      person = people.first
    elsif people.length > 1
      # try to narrow it down based on name in the from line
      people = people.select do |p|
        p.name.downcase.split.first == email.friendly_from.to_s.downcase.split.first
      end
      person = people.first if people.length == 1
    end

    message_sent_to_group = false

    if person
      (email.cc.to_a + email.to.to_a).each do |address|
        address, domain = address.downcase.split('@')
        if domain.to_s.strip.downcase == Site.current.host
          address = address.to_s.strip
          if address.any? and group = Group.find_by_address(address.downcase) and group.can_send? person
            # if is this a reply, link this message to its original based on the subject
            if email.subject =~ /^re:/i
              parent = group.messages.find_by_subject(email.subject.gsub(/^re:\s?/i, ''), :order => 'id desc')
            else
              parent = nil
            end
            # if the message is multipart, try to grab the plain text part
            # and any attachments
            if email.multipart?
              parts = email.parts.select { |p| p.content_type.downcase == 'text/plain' }
              body = parts.any? ? parts.first.body : nil
            else
              body = email.body
            end
            # if there is a readable body, send the message
            if body
              body = clean_body(body)
              message = Message.create(
                :group => group,
                :parent => parent,
                :person => person,
                :subject => email.subject,
                :body => body,
                :dont_send => true
              )
              if message.errors.any?
                if message.errors.on_base != 'already saved' and message.errors.on_base != 'autoreply'
                  # notify user there were some errors
                  Notifier.deliver_simple_message(email.from, 'Message Error', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{Setting.get(:name, :site)} site had trouble saving the message (#{message.errors.full_messages.join('; ')}). You may post your message directly from the site after signing into #{Setting.get(:url, :site)}. If you continue to have trouble, please contact #{Setting.get(:contact, :tech_support_contact)}.")
                end
              else
                if email.has_attachments?
                  email.attachments.each do |attachment|
                    name = File.split(attachment.original_filename.to_s).last
                    unless ATTACHMENTS_TO_IGNORE.include? name.downcase
                      message.attachments.create(
                        :name => name,
                        :file => attachment.read,
                        :content_type => attachment.content_type.strip
                      )
                    end
                  end
                end
                message.send_to_group
                message_sent_to_group = true
              end
            else
              # notify the sender of the failure and ask to resend as plain text
              Notifier.deliver_simple_message(email.from, 'Message Unreadable', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{Setting.get(:name, :site)} site cannot read the message because it is not formatted as plain text nor does it have a plain text part. Please format your message as plain text (turn off Rich Text or HTML formatting in your email client), or you may post your message directly from the site after signing into #{Setting.get(:url, :site)}. If you continue to have trouble, please contact #{Setting.get(:contact, :tech_support_contact)}.")
            end
          
          # replying to a person who sent a group message
          elsif address.to_s.any? and address =~ /^[a-z]*\.\d+\.[0-9abcdef]{6,6}$/ and not message_sent_to_group
            name, message_id, code_hash = address.split('.')
            message = Message.find(message_id) rescue nil
            if message and Digest::MD5.hexdigest(message.code.to_s)[0..5] == code_hash
              if message.created_at < (DateTime.now - MAX_DAYS_FOR_REPLIES)
                # notify the sender that the message they're replying to is too old
                Notifier.deliver_simple_message(email.from, 'Message Too Old', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the message to which you're replying is too old. This is to prevent unsolicited email to our users. If you wish to send a message to this person, please sign into #{Setting.get(:url, :site)} and send the message via the web site. If you need help, please contact #{Setting.get(:contact, :tech_support_contact)}.")
              else
                to_person = message.person
                # if the message is multipart, try to grab the plain text part
                if email.multipart?
                  parts = email.parts.select { |p| p.content_type.downcase == 'text/plain' }
                  body = parts.any? ? parts.first.body : nil
                else
                  body = email.body
                end
                if body
                  body = clean_body(body)
                  message = Message.create(
                    :to => to_person,
                    :person => person,
                    :subject => email.subject,
                    :body => body,
                    :parent => message
                  )
                  if message.errors.any? and message.errors.on_base != 'already saved' and message.errors.on_base != 'autoreply'
                    # notify user there were some errors
                    Notifier.deliver_simple_message(email.from, 'Message Error', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{Setting.get(:name, :site)} site had trouble saving the message (#{message.errors.full_messages.join('; ')}). You may post your message directly from the site after signing into #{Setting.get(:url, :site)}. If you continue to have trouble, please contact #{Setting.get(:contact, :tech_support_contact)}.")
                  end
                else
                  # notify the sender of the failure and ask to resend as plain text
                  Notifier.deliver_simple_message(email.from, 'Message Unreadable', "Your message with subject \"#{email.subject}\" was not delivered.\n\nSorry for the inconvenience, but the #{Setting.get(:name, :site)} site cannot read the message because it is not formatted as plain text nor does it have a plain text part. Please format your message as plain text (turn off Rich Text or HTML formatting in your email client), or you may send your message directly from the site after signing into #{Setting.get(:url, :site)}. If you continue to have trouble, please contact #{Setting.get(:contact, :tech_support_contact)}.")
                end
              end
            end
          end
        end
      end
    end
  end
  
  private
  
    def clean_body(body)
      # this has the potential for error, but we'll just go with it and see
      body.split(/^[>\s]*\- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \-/).first.strip
    end
    
    #def parse_html_body(body)
    #  # a work in progress
    #  body.gsub(/\n/, '').gsub(/<br\s?\/?>/i, "\n").gsub(/<(p|div)>/i, "\n").gsub(/<script.*?>.*?</script>/i, '').gsub(/<.+?>/m, '').gsub(/&nbsp;/, ' ').strip
    #end
end
