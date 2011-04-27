require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base
  MESSAGE_ID_RE = /<(\d+)_([0-9abcdef]{6})_/
  MESSAGE_ID_RE_IN_BODY = /id:\s*(\d+)_([0-9abcdef]{6})/i

  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_person_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :conditions => 'to_person_id is null', :dependent => :destroy
  has_many :attachments, :dependent => :destroy
  has_many :log_items, :foreign_key => 'loggable_id', :conditions => "loggable_type = 'Message'"
  belongs_to :site

  scope_by_site_id

  validates_presence_of :person_id
  validates_presence_of :subject
  validates_length_of :subject, :minimum => 2

  validates_each :to_person_id, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'to_person_id' and value and record.to and record.to.email.nil?
      record.errors.add attribute, :invalid
    end
  end

  validates_each :body do |record, attribute, value|
    if attribute.to_s == 'body' and value.to_s.blank? and record.html_body.to_s.blank?
      record.errors.add attribute, :blank
    end
  end

  acts_as_logger LogItem

  def name
    if self.to
      "Private Message to #{to.name rescue '[deleted]'}"
    elsif wall
      "Post on #{wall.name_possessive rescue '[deleted]'} Wall"
    elsif parent
      "Reply to \"#{parent.subject}\" in Group #{top.group.name rescue '[deleted]'}"
    else
      "Message \"#{subject}\" in Group #{group.name rescue '[deleted]'}"
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
      body.gsub! /http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--'
    end
    if html_body
      html_body.gsub! /http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--'
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

  validate :on => :create do |record|
    if Message.find_by_person_id_and_subject_and_body(record.person_id, record.subject, record.body, :conditions => ['created_at >= ?', Date.today-1])
      record.errors.add :base, 'already saved' # Notifier relies on this message (don't change it)
    end
    if record.subject =~ /Out of Office/i
      record.errors.add :base, 'autoreply' # don't change!
    end
  end

  attr_accessor :dont_send

  after_create :send_message

  def send_message
    return if dont_send
    if group
      send_to_group
    elsif to
      send_to_person(to)
    elsif wall
      send_to_person(wall) if wall.get_wall_email
    end
  end

  def send_to_person(person)
    if person.email.to_s.any?
      email = Notifier.full_message(person, self, id_and_code)
      email.add_message_id
      email.message_id = "<#{id_and_code}_#{email.message_id.gsub(/^</, '')}"
      email.deliver
    end
  end

  def send_to_group(sent_to=[])
    return unless group
    group.people.each do |person|
      if group.get_options_for(person).get_email and person.email.to_s.any? and person.email =~ VALID_EMAIL_ADDRESS and not sent_to.include?(person.email)
        send_to_person(person)
        sent_to << person.email
      end
    end
  end

  def id_and_code
    "#{self.id.to_s}_#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
  end

  def introduction(to_person)
    if wall
      "#{person.name} posted a message on your wall:\n#{'- ' * 24}\n"
    else
      ''
    end
  end

  def reply_url
    if group
      "#{Setting.get(:url, :site)}messages/view/#{self.id.to_s}"
    elsif wall
      "#{Setting.get(:url, :site)}people/#{person_id}#wall"
    else
      reply_subject = self.subject
      reply_subject = "RE: #{subject}" unless reply_subject =~ /^re:/i
      "#{Setting.get(:url, :site)}messages/send_email/#{self.person.id}?subject=#{URI.escape(reply_subject)}"
    end
  end

  def reply_instructions(to_person)
    msg = ''
    if to
      msg << "Hit \"Reply\" to send a message to #{self.person.name rescue 'the sender'} only.\n"
    elsif group
      msg << "Hit \"Reply\" to send a message to #{self.person.name rescue 'the sender'} only.\n"
      if group.can_post? to_person
        if group.address.to_s.any?
          msg << "Hit \"Reply to All\" to send a message to the group, or send to: #{group.address + '@' + Site.current.host}\n"
          msg << "Group page: #{Setting.get(:url, :site)}groups/#{group.id}\n"
        else
          msg << "To reply: #{reply_url}\n"
        end
      end
    elsif wall
      msg << "Your wall: #{Setting.get(:url, :site)}people/#{wall_id}#wall\n\n"
      msg << "#{self.person.name_possessive} wall: #{reply_url}\n"
    end
    msg
  end

  def disable_email_instructions(to_person)
    msg = ''
    if group
      msg << "To stop email from this group: "
      if new_record?
        msg << '-link to turn off email-'
      else
        msg << disable_group_email_link(to_person)
      end
    else
      msg << "To stop these emails, go to your privacy page:\n#{Setting.get(:url, :site)}privacy"
    end
    msg + "\n"
  end

  def disable_group_email_link(to_person)
    "#{Setting.get(:url, :site)}groups/#{group.id}/memberships/#{to_person.id}?code=#{to_person.feed_code}&email=off"
  end

  def email_from(to_person)
    if wall or not to_person.messages_enabled?
      "\"#{person.name}\" <#{Site.current.noreply_email}>"
    elsif group
      relay_address("#{person.name} [#{group.name}]")
    else
      relay_address(person.name)
    end
  end

  def email_reply_to(to_person)
    if wall or not to_person.messages_enabled?
      "\"DO NOT REPLY\" <#{Site.current.noreply_email}>"
    else
      relay_address(person.name)
    end
  end

  def relay_address(name)
    if person.email.to_s.any? and person.share_email? and !Setting.get(:privacy, :relay_all_email)
      "\"#{name}\" <#{person.email}>"
    else # special time-limited address that relays a private message directly back to the sender
      email = person.name.downcase.scan(/[a-z]/).join('')
      email = email + person.id.to_s if Group.find_by_address(email)
      "\"#{name}\" <#{email + '@' + Site.current.host}>"
    end
  end

  before_create :generate_security_code

  def generate_security_code
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end

  def flagged?
    log_items.count(:id, :conditions => "flagged_on is not null") > 0
  end

  def can_see?(p)
    if group and group.private?
      p.member_of?(group) or group.admin?(p)
    elsif group
      p.member_of?(group) or group.admin?(p)
    elsif wall and not wall.wall_enabled?
      p == wall
    elsif wall
      p.can_see?(wall)
    elsif to
      to == p or person == p
    else
      raise 'Invalid message.'
    end
  end

  def code_hash
    Digest::MD5.hexdigest(code.to_s)[0..5]
  end

  def streamable?
    person_id and not to_person_id and (wall_id or group)
  end

  after_create :create_as_stream_item

  def create_as_stream_item
    return unless streamable?
    StreamItem.create!(
      :title           => wall_id ? nil : subject,
      :body            => html_body.to_s.any? ? html_body : body,
      :text            => !html_body.to_s.any?,
      :wall_id         => wall_id,
      :person_id       => person_id,
      :group_id        => group_id,
      :streamable_type => 'Message',
      :streamable_id   => id,
      :created_at      => created_at,
      :shared          => (!wall || wall.share_activity?) && person.share_activity? && !(group && group.hidden?)
    )
  end

  after_update :update_stream_items

  def update_stream_items
    return unless streamable?
    StreamItem.find_all_by_streamable_type_and_streamable_id('Message', id).each do |stream_item|
      stream_item.title = wall_id ? nil : subject
      if html_body.to_s.any?
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
    StreamItem.destroy_all(:streamable_type => 'Message', :streamable_id => id)
  end

  def self.preview(attributes)
    msg = Message.new(attributes)
    Notifier.full_message(Person.new(:email => 'test@example.com'), msg)
  end

  def self.create_with_attachments(attributes, files)
    message = Message.create(attributes.update(:dont_send => true))
    unless message.errors.any?
      files.select { |f| f && f.size > 0 }.each do |file|
        attachment = message.attachments.create(
          :name         => File.split(file.original_filename).last,
          :content_type => file.content_type,
          :file         => file
        )
        if attachment.errors.any?
          attachment.errors.each_full { |e| message.errors.add(:base, e) }
          return message
        end
      end
      message.dont_send = false
      message.send_message
    end
    message
  end

  def self.daily_counts(limit, offset, date_strftime='%Y-%m-%d', only_show_date_for=nil)
    [].tap do |data|
      private_counts = connection.select_all("select count(date(created_at)) as count, date(created_at) as date from messages where to_person_id is not null and site_id=#{Site.current.id} group by date(created_at) order by created_at desc limit #{limit} offset #{offset};").group_by { |p| Date.parse(p['date']) }
      group_counts   = connection.select_all("select count(date(created_at)) as count, date(created_at) as date from messages where group_id     is not null and site_id=#{Site.current.id} group by date(created_at) order by created_at desc limit #{limit} offset #{offset};").group_by { |p| Date.parse(p['date']) }
      ((Date.today-offset-limit+1)..(Date.today-offset)).each do |date|
        d = date.strftime(date_strftime)
        d = ' ' if only_show_date_for and date.strftime(only_show_date_for[0]) != only_show_date_for[1]
        private_count = private_counts[date] ? private_counts[date][0]['count'].to_i : 0
        group_count   = group_counts[date]   ? group_counts[date][0]['count'].to_i   : 0
        data << [d, private_count, group_count]
      end
    end
  end
end
