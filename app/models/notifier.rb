class Notifier < ActionMailer::Base
  helper :application

  default charset: 'UTF-8', from: ->(_) { get_from_address.to_s }

  def profile_update(person)
    @person = person
    mail(
      to:      Setting.get(:contact, :send_updates_to),
      subject: I18n.t('notifier.profile_update.subject', person: person.name)
    )
  end

  def email_update(person)
    to_address = Setting.get(:contact, :send_email_changes_to)
    return unless to_address.present?
    @person = person
    mail(
      to:      to_address,
      subject: I18n.t('notifier.email_update.subject', person: person.name)
    )
  end

  def friend_request(person, friend)
    @person = person
    @friend = friend
    mail(
      to:      friend.formatted_email,
      subject: I18n.t('notifier.friend_request.subject', person: person.name)
    )
  end

  def membership_request(group, person)
    @group = group
    @person = person
    unless (to = group.admins.select { |p| p.email.present? }.map { |p| "#{p.name} <#{p.email}>" }).any?
      unless (to = Admin.all.select(&:manage_updates?).map { |a| "#{a.person.name} <#{a.person.email}>" }).any?
        to = Admin.where(super_admin: true).map { |a| a.person.email }
      end
    end
    return unless to.present?
    mail(
      to:      to,
      from:    person.formatted_email || Site.current.noreply_email,
      subject: I18n.t('notifier.membership_request.subject', person: person.name)
    )
  end

  def prayer_request(prayer_request, group, person)
    @prayer_request = prayer_request
    @group = group
    mail(
      to:       person.email,
      from:     prayer_request.person.email,
      subject:  t('notifier.prayer_request.subject', group: group.try(:name))
    )
  end

  def full_message(to, msg, id_and_code = nil)
    @to          = to
    @msg         = msg
    @id_and_code = id_and_code
    h = { 'Reply-To' => msg.email_reply_to(to) }
    if msg.group
      unless to.new_record? # allows preview to work
        h.update(
          'List-ID' => "#{msg.group.name} group on #{Setting.get(:name, :site)} <#{msg.group.address}.#{URI.parse(Setting.get(:url, :site)).host}>",
          'List-Help' => "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>",
          'List-Unsubscribe' => msg.disable_group_email_link(to),
          'List-Post' => (msg.group.can_post?(to) ? "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>" : "NO (#{I18n.t('notifier.not_allowed_to_post')})"),
          'List-Archive' => "<#{Setting.get(:url, :site)}groups/#{msg.group.id}>"
        )
      end
      if msg.group.address.present? && msg.group.can_post?(msg.person)
        h.update 'CC' => "\"#{msg.group.name}\" <#{msg.group.address + '@' + Site.current.email_host}>"
      end
    end
    headers h
    msg.attachments.each do |a|
      attachments[a.name] = File.read(a.file.path)
    end
    mail(
      to:      to.email,
      from:    msg.email_from(to),
      subject: msg.subject
    ) do |format|
      format.text if msg.body.present?
      format.html if msg.html_body.present?
    end
  end

  # used for auto-generated responses
  def simple_message(t, s, b, f = nil)
    headers 'Auto-Submitted' => 'auto-replied'
    mail(
      to:      t,
      from:    f || Site.current.noreply_email,
      subject: s
    ) do |format|
      format.text { render plain: b }
    end
  end

  def attendance_submission(group, attendance_records, submitter, notes)
    @group = group
    @attendance_records = attendance_records
    @person = submitter
    @notes = notes
    mail(
      to: Setting.get(:contact, :send_attendance_submissions_to),
      subject: t('attendance.email.subject', group: group.name)
    )
  end

  def email_verification(verification)
    @verification = verification
    mail(
      to:      verification.email,
      subject: I18n.t('notifier.email_verification.subject')
    )
  end

  def mobile_verification(verification)
    @verification = verification
    mail(
      to:      verification.email,
      subject: I18n.t('notifier.mobile_verification.subject')
    )
  end

  def pending_sign_up(person)
    @person = person
    mail(
      to:      Setting.get(:features, :sign_up_approval_email),
      subject: I18n.t('notifier.pending_sign_up.subject')
    )
  end

  def photo_update(person, is_family)
    @person = person
    mail(
      to:      Setting.get(:features, :send_updates_to),
      subject: I18n.t(is_family ? 'family_subject' : 'person_subject', scope: 'notifier.photo_update')
    )
  end

  def printed_directory(person, file)
    @person = person
    attachments['directory.pdf'] = file.read
    mail(
      to:      "\"#{person.name}\" <#{person.email}>",
      subject: I18n.t('notifier.printed_directory.subject', site: Setting.get(:name, :site))
    )
  end

  def receive(email)
    sent_to = Array(email.cc) + Array(email.to) # has to be reversed (cc first) so that group replies work right

    return unless email.from.present?
    return if email['Auto-Submitted'] && !%w(false no).include?(email['Auto-Submitted'].to_s.downcase)
    return if email['Return-Path'] && ['<>', ''].include?(email['Return-Path'].to_s)
    return if sent_to.any? { |a| a =~ /no\-?reply|postmaster|mailer\-daemon/i }
    return if email.from.to_s =~ /no\-?reply|postmaster|mailer\-daemon/i
    return if email.subject =~ /^undelivered mail returned to sender|^returned mail|^delivery failure/i
    return if email.message_id =~ Message::MESSAGE_ID_RE && (m = Message.unscoped { Message.where(id: Regexp.last_match(1)).first }) && m.code_hash == Regexp.last_match(2) # just sent, looping back into the receiver
    return if ProcessedMessage.where(header_message_id: email.message_id).any?
    return unless Site.current = get_site(email)

    destinations = sent_to.map do |address|
      address, domain = address.strip.downcase.split('@')
      next unless address.present? && domain.present?
      next unless [Site.current.email_host, Site.current.secondary_host].compact.include?(domain)
      Group.where(address: address).first
    end.compact

    @person = get_from_person(email, destinations)

    if [nil, :multiple].include?(@person)
      if @person == :multiple
        reject_subject = I18n.t('notifier.rejection.multiple_people.subject', subject: email.subject)
        reject_msg = I18n.t('notifier.rejection.multiple_people.body',
                            subject: email.subject,
                            url: Setting.get(:url, :site))
      else
        reject_subject = I18n.t('notifier.rejection.unknown_person.subject', subject: email.subject)
        reject_msg = I18n.t('notifier.rejection.unknown_person.body',
                            subject: email.subject,
                            url: Setting.get(:url, :site))
      end
      if destinations.any? && (return_to = email['Return-Path'] ? email['Return-Path'].to_s : email.from)
        Notifier.simple_message(return_to, reject_subject, reject_msg).deliver_now
      end
      return
    end

    unless (body = get_body(email)) && (body[:text] || body[:html])
      Notifier.simple_message(
        email['Return-Path'] ? email['Return-Path'].to_s : email.from,
        I18n.t('notifier.rejection.cannot_read.subject', subject: email.subject),
        I18n.t('notifier.rejection.cannot_read.body', subject: email.subject, url: Setting.get(:url, :site))
      ).deliver_now
      return
    end

    @message_sent_to_group = false
    sent_to_count = 0

    destinations.each do |group|
      next unless group.can_send?(@person)
      message = group_email(group, email, body)
      if @message_sent_to_group
        sent_to_count += 1
      elsif !message.valid? && message.errors[:base] !~ /already saved|autoreply/
        Notifier.simple_message(
          email['Return-Path'] ? email['Return-Path'].to_s : email.from,
          I18n.t('notifier.rejection.invalid.subject', subject: email.subject),
          I18n.t('notifier.rejection.invalid.body',
                 subject: email.subject,
                 errors: message.errors.values.join("\n"),
                 support: Setting.get(:contact, :tech_support_contact))
        ).deliver_now
        sent_to_count += 1
        break
      end
    end

    if sent_to_count == 0 && (return_to = email['Return-Path'] ? email['Return-Path'].to_s : email.from)
      # notify the sender that no mail was sent
      Notifier.simple_message(
        return_to,
        I18n.t('notifier.rejection.no_recipients.subject', subject: email.subject),
        I18n.t('notifier.rejection.no_recipients.body',
               subject: email.subject,
               url: Setting.get(:url, :site))
      ).deliver_now
    end

    # do not process this one ever again
    ProcessedMessage.create(
      header_message_id: email.message_id
    )
  end

  private

  def group_email(group, email, body)
    # if is this looks like a reply, try to link this message to its original based on the subject
    parent = if email.subject =~ /^re:/i
               group.messages.where(subject: email.subject.sub(/^re:\s?/i, '')).order('id desc').first
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
      create_attachments(email, message)
      already_sent_to = email.to.to_a
      message.send_to_group(already_sent_to)
      @message_sent_to_group = true
    end
    message
  end

  def create_attachments(email, message)
    if email.has_attachments?
      email.attachments.each do |attachment|
        name = File.split(attachment.filename.to_s).last
        next if ATTACHMENTS_TO_IGNORE.include? name.downcase
        message.attachments.create(
          name:         name,
          content_type: attachment.content_type.strip,
          file:         FakeFile.new(attachment.body.to_s, name)
        )
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
    # prefer the cc address (for reply-all), then the to address
    to_addresses = Array(email.cc) + Array(email.to)
    site = nil
    to_addresses.each do |address|
      next if address.nil?
      site = Site.where(host: address.downcase.split('@').last).first ||
        Site.where(email_host: address.downcase.split('@').last).first
      return site if site
    end
    # fallback if address was rewritten
    # Calvin College in MI is known to rewrite our from/reply-to addresses
    # to be the same as the host that made the connection
    if get_body(email).to_s =~ Message::MESSAGE_ID_RE_IN_BODY
      Site.each do |site|
        return site if get_in_reply_to_message_and_code(email)
      end
    end
    nil
  end

  def get_from_person(email, destinations)
    people = Person.where('lower(email) = ?', email.from.first.downcase).to_a
    if people.none?
      # user is not found in the system, try alternate email
      Person.where('lower(alternate_email) = ?', email.from.first.downcase).first
    elsif people.one?
      people.first
    else
      get_from_person_by_primary(people) ||
        get_from_person_by_name(people, email) ||
        get_from_person_by_group(people, destinations) ||
        :multiple
    end
  end

  def get_from_person_by_primary(people)
    by_primary = people.select(&:primary_emailer?)
    by_primary.first if by_primary.one?
  end

  def get_from_person_by_name(people, email)
    name = email.header['from'].value.to_s.downcase.split.first
    by_name = people.select do |p|
      p.name.downcase.split.first == name
    end
    by_name.first if by_name.one?
  end

  def get_from_person_by_group(people, destinations)
    by_group = find_person_by_group(people, destinations)
    by_group.first if by_group.one?
  end

  def find_person_by_group(people, groups)
    people.select do |person|
      groups.any? { |g| person.member_of?(g) }
    end
  end

  def get_body(email)
    self.class.get_body(email)
  end

  def self.get_body(email)
    body = {
      text: email.text_part.try(:decoded),
      html: email.html_part.try(:decoded)
    }
    type = email.content_type.downcase.split(';').first
    if body[:text].nil? && type == 'text/plain'
      body[:text] = email.decoded
    elsif body[:html].nil? && type == 'text/html'
      body[:html] = email.decoded
    end
    body
  end

  def clean_body(body)
    # this has the potential for error, but we'll just go with it and see
    body.to_s.split(/^[>\s]*\- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \- \-/).first.to_s.strip
  end

  def get_from_address
    Mail::Address.new.tap do |addr|
      addr.address = Site.current.noreply_email
      addr.display_name = Setting.get(:name, :site).dup
    end
  end
end
