require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'MessageAuthorizer'

  MESSAGE_ID_RE = /<(\d+)_([0-9abcdef]{6})_/
  MESSAGE_ID_RE_IN_BODY = /id:\s*(\d+)_([0-9abcdef]{6})/i

  belongs_to :group
  belongs_to :person
  belongs_to :to, class_name: 'Person', foreign_key: 'to_person_id'
  belongs_to :parent, class_name: 'Message', foreign_key: 'parent_id'
  has_many :children, -> { where('to_person_id is null') }, class_name: 'Message', foreign_key: 'parent_id', dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :log_items, -> { where(loggable_type: 'Message') }, foreign_key: 'loggable_id'
  belongs_to :site

  scope_by_site_id

  scope :same_as, -> m { where('id != ?', m.id || 0).where(person_id: m.person_id, subject: m.subject, body: m.body, to_person_id: m.to_person_id, group_id: m.group_id).where('created_at >= ?', 1.day.ago) }

  validates_presence_of :person_id
  validates_presence_of :subject
  validates_length_of :subject, minimum: 2

  validates_each :to_person_id, allow_nil: true do |record, attribute, value|
    if attribute.to_s == 'to_person_id' and value and record.to and record.to.email.nil?
      record.errors.add attribute, :invalid
    end
  end

  validates_each :body do |record, attribute, value|
    if attribute.to_s == 'body' and value.to_s.blank? and record.html_body.to_s.blank?
      record.errors.add attribute, :blank
    end
  end

  def top
    top = self
    while top.parent
      top = top.parent
    end
    return top
  end

  before_save :remove_unsubscribe_link

  def remove_unsubscribe_link
    if body
      body.gsub!(/http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--')
    end
    if html_body
      html_body.gsub!(/http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--')
    end
  end

  before_save :remove_message_id_in_body

  def remove_message_id_in_body
    if body
      body.gsub! MESSAGE_ID_RE_IN_BODY, ''
    end
    if html_body
      html_body.gsub! MESSAGE_ID_RE_IN_BODY, ''
    end
  end

  validate on: :create do |record|
    if Message.same_as(self).any?
      record.errors.add :base, 'already saved' # Notifier relies on this message (don't change it)
      record.errors.add :base, :taken
    end
    if record.subject =~ /Out of Office/i
      record.errors.add :base, 'autoreply' # don't change!
    end
  end

  attr_accessor :dont_send

  after_create :enqueue_send

  def enqueue_send
    return if dont_send
    MessageSendJob.perform_later(Site.current, id)
  end

  def send_message
    if group
      send_to_group
    elsif to
      send_to_person(to)
    end
  end

  def send_to_person(person)
    if person.email.present?
      email = Notifier.full_message(person, self, id_and_code)
      email.add_message_id
      email.message_id = "<#{id_and_code}_#{email.message_id.gsub(/^</, '')}"
      email.deliver_now
    end
  end

  def send_to_group(sent_to=[])
    return unless group
    group.people.each do |person|
      if should_send_group_email_to_person?(person, sent_to)
        send_to_person(person)
        sent_to << person.email
      end
    end
  end

  def should_send_group_email_to_person?(person, sent_to)
    person.email.present? and
    person.email =~ VALID_EMAIL_ADDRESS and
    group.get_options_for(person).get_email? and
    not sent_to.include?(person.email)
  end

  def id_and_code
    "#{id}_#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
  end

  def reply_url
    if group
      "#{Setting.get(:url, :site)}messages/#{id}"
    else
      reply_subject = subject
      reply_subject = "RE: #{subject}" unless reply_subject =~ /^re:/i
      "#{Setting.get(:url, :site)}messages/new?to_person_id=#{person.id}?subject=#{URI.escape(reply_subject)}"
    end
  end

  def reply_instructions(to_person)
    msg = []
    if to || group
      msg << I18n.t('messages.email.reply_to_sender', person: person.try(:name))
    end
    if group
      if group.can_post?(to_person)
        if group.address.present?
          msg << I18n.t('messages.email.reply_to_group', group: group.try(:name), address: group.try(:full_address))
        else
          msg << I18n.t('messages.email.reply_link', url: reply_url)
        end
      end
      msg << I18n.t('messages.email.group_link', url: "#{Setting.get(:url, :site)}groups/#{group.id}")
    end
    msg.join("\n") + "\n"
  end

  def disable_email_instructions(to_person)
    msg = []
    if group
      msg << I18n.t('messages.email.disable_group_email', url: disable_group_email_link(to_person))
    else
      msg << I18n.t('messages.email.disable_all_email', url: "#{Setting.get(:url, :site)}privacy")
    end
    msg.join("\n") + "\n"
  end

  def disable_group_email_link(to_person)
    return if new_record?
    "#{Setting.get(:url, :site)}groups/#{group.id}/memberships/#{to_person.id}?code=#{to_person.feed_code}&email=off"
  end

  def email_from(to_person)
    if group
      from_address("#{person.name} [#{group.name}]")
    else
      from_address(person.name)
    end
  end

  def email_reply_to(to_person)
    if not to_person.messages_enabled?
      "\"#{I18n.t('messages.do_not_reply')}\" <#{Site.current.noreply_email}>"
    else
      from_address(person.name, :real)
    end
  end

  def from_address(name, real=false)
    if person.email.present?
      %("#{name.gsub(/"/, '')}" <#{real ? person.email : Site.current.noreply_email}>)
    else
      "\"#{I18n.t('messages.do_not_reply')}\" <#{Site.current.noreply_email}>"
    end
  end

  before_create :generate_security_code

  def generate_security_code
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end

  def code_hash
    Digest::MD5.hexdigest(code.to_s)[0..5]
  end

  def streamable?
    person_id and not to_person_id and group
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless streamable?
    StreamItem.create!(
      title:           subject,
      body:            html_body.present? ? html_body : body,
      text:            !html_body.present?,
      person_id:       person_id,
      group_id:        group_id,
      streamable_type: 'Message',
      streamable_id:   id,
      created_at:      created_at,
      shared:          !!group
    )
  end

  after_update :update_stream_items

  def update_stream_items
    return unless streamable?
    StreamItem.where(streamable_type: "Message", streamable_id: id).each do |stream_item|
      stream_item.title = subject
      if html_body.present?
        stream_item.body = html_body
        stream_item.text = false
      else
        stream_item.body = body
        stream_item.text = true
      end
      stream_item.save
    end
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'Message', streamable_id: id)
  end

  def self.preview(attributes)
    msg = Message.new(attributes)
    Notifier.full_message(Person.new(email: 'test@example.com'), msg)
  end

  def self.create_with_attachments(attributes, files)
    message = Message.create(attributes.update(dont_send: true))
    unless message.errors.any?
      files.select { |f| f && f.size > 0 }.each do |file|
        attachment = message.attachments.create(
          name:         File.split(file.original_filename).last,
          content_type: file.content_type,
          file:         file
        )
        if attachment.errors.any?
          attachment.errors.each_full { |e| message.errors.add(:base, e) }
          return message
        end
      end
      message.dont_send = false
      message.enqueue_send
    end
    message
  end
end
