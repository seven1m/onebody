require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base
  include Authority::Abilities
  include Concerns::Message::Streamable
  include Concerns::Message::Sendable
  self.authorizer_name = 'MessageAuthorizer'

  MESSAGE_ID_RE = /<(\d+)_([0-9abcdef]{6})_/
  MESSAGE_ID_RE_IN_BODY = /id:\s*(\d+)_([0-9abcdef]{6})/i

  belongs_to :group
  belongs_to :person
  belongs_to :to, class_name: 'Person', foreign_key: 'to_person_id'
  belongs_to :parent, class_name: 'Message', foreign_key: 'parent_id'
  has_many :children, -> { where('to_person_id is null') },
           class_name: 'Message', foreign_key: 'parent_id', dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :log_items, -> { where(loggable_type: 'Message') }, foreign_key: 'loggable_id'
  belongs_to :site
  has_and_belongs_to_many :members, class_name: 'Person', join_table: :members_messages, association_foreign_key: :member_id

  scope_by_site_id
  scope(:same_as, lambda do |m|
    where('id != ?', m.id || 0)
      .where(person_id:    m.person_id,
             subject:      m.subject,
             body:         m.body,
             to_person_id: m.to_person_id,
             group_id:     m.group_id)
      .where('created_at >= ?', 1.day.ago)
  end)
  scope(:for_user, lambda do |user|
    joins(:members).where('members_messages.member_id = ? OR messages.person_id = ?', user.id, user.id).uniq 
  end)
  scope :for_whole_group, -> { includes(:members).where(members_messages: { :message_id => nil }) }

  validates_presence_of :person_id
  validates_length_of :subject, minimum: 2
  validate do |message|
    errors.add(:to, :invalid) if message.to && message.to.email.nil?
    errors.add(:body, :blank) unless body || html_body
  end

  def top(top_message = self)
    top_message.parent ? top(top_message.parent) : top_message
  end

  before_save do
    self.body &&= body.gsub(%r{http://.*?person_id=\d+&code=\d+}i, '--removed--').gsub(MESSAGE_ID_RE_IN_BODY, '')
    self.html_body &&= html_body.gsub(%r{http://.*?person_id=\d+&code=\d+}i, '--removed--')
                                .gsub(MESSAGE_ID_RE_IN_BODY, '')
    self.code ||= rand(999_999) + 1
    self.member_ids = parent.member_ids << parent.person_id if group_id? && parent_id? && parent.member_ids.any?
  end

  validate on: :create do |record|
    if Message.same_as(self).any?
      record.errors.add :base, 'already saved' # Notifier relies on this message (don't change it)
      record.errors.add :base, :taken
    end
    record.errors.add :base, 'autoreply' if record.subject =~ /Out of Office/i # don't change!
  end

  def id_and_code
    "#{id}_#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
  end

  def reply_url
    return "#{Setting.get(:url, :site)}messages/#{id}" if group
    reply_subject = subject =~ /^re:/i ? subject : "RE: #{subject}"
    "#{Setting.get(:url, :site)}messages/new?to_person_id=#{person.id}?subject=#{URI.escape(reply_subject)}"
  end

  def reply_instructions(to_person)
    msg = []
    msg << I18n.t('messages.email.reply_to_sender', person: person.try(:name)) if to || group
    (msg << case
            when group.address.present?
              I18n.t('messages.email.reply_to_group',
                     group:   group.try(:name),
                     address: group.try(:full_address))
            else
              I18n.t('messages.email.reply_link',
                     url: reply_url)
            end) if group && group.can_post?(to_person)
    msg << I18n.t('messages.email.group_link', url: "#{Setting.get(:url, :site)}groups/#{group.id}") if group
    msg.join("\n") << "\n"
  end

  def disable_email_instructions(to_person)
    return I18n.t('messages.email.disable_group_email', url: disable_group_email_link(to_person)) << "\n" if group
    I18n.t('messages.email.disable_all_email', url: "#{Setting.get(:url, :site)}privacy") << "\n"
  end

  def disable_group_email_link(to_person)
    return if new_record?
    "#{Setting.get(:url, :site)}groups/#{group.id}/memberships/#{to_person.id}?code=#{to_person.feed_code}&email=off"
  end

  def email_from(*)
    from_address(group ? "#{person.name} [#{group.name}]" : person.name)
  end

  def email_reply_to(to_person)
    return from_address(person.name, :real) if to_person.messages_enabled?
    "\"#{I18n.t('messages.do_not_reply')}\" <#{Site.current.noreply_email}>"
  end

  def from_address(name, real = false)
    if person.email.present?
      %("#{name.delete('"')}" <#{real ? person.email : Site.current.noreply_email}>)
    else
      "\"#{I18n.t('messages.do_not_reply')}\" <#{Site.current.noreply_email}>"
    end
  end

  def code_hash
    Digest::MD5.hexdigest(code.to_s)[0..5]
  end

  def self.preview(attributes)
    Notifier.full_message(Person.new(email: 'test@example.com'), Message.new(attributes))
  end

  def self.create_with_attachments(attributes, files)
    message = Message.create(attributes.update(dont_send: true))
    message.attach_files(files) unless message.errors.any?
  end

  def attach_files(files)
    files.reject { |f| f.size.zero? }.each do |file|
      attachment = attachments.create(
        name:         File.split(file.original_filename).last,
        content_type: file.content_type,
        file:         file
      )
      attachment.errors.full_messages.each { |e| errors.add(:base, e) }
      return self if errors.any?
    end
    self.dont_send = false
    enqueue_send
    self
  end
end
