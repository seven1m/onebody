# == Schema Information
# Schema version: 20080409165237
#
# Table name: messages
#
#  id           :integer       not null, primary key
#  group_id     :integer       
#  person_id    :integer       
#  to_person_id :integer       
#  created_at   :datetime      
#  updated_at   :datetime      
#  parent_id    :integer       
#  subject      :string(255)   
#  body         :text          
#  share_email  :boolean       
#  wall_id      :integer       
#  code         :integer       
#  site_id      :integer       
#

require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_person_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :conditions => 'to_person_id is null', :dependent => :destroy
  has_many :attachments, :dependent => :destroy
  has_many :log_items, :foreign_key => 'instance_id', :conditions => "model_name = 'Message'"
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  validates_presence_of :person_id
  validates_presence_of :subject
  validates_length_of :subject, :minimum => 2
  validates_presence_of :body
  validates_length_of :body, :minimum => 2
  
  validates_each :to_person_id, :allow_nil => true do |record, attribute, value|
    if attribute.to_s == 'to_person_id' and value and record.to and record.to.email.nil?
      record.errors.add attribute, 'has no email address'
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
  
  def before_save
    body.gsub! /http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--'
  end

  validate_on_create do |record|
    if Message.find_by_person_id_and_subject_and_body(record.person_id, record.subject, record.body, :conditions => ['created_at >= ?', Date.today-1])
      record.errors.add_to_base 'already saved' # Notifier relies on this message (don't change it)
    end
    if record.subject =~ /Out of Office/i
      record.errors.add_to_base 'autoreply' # don't change!
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
      id_and_code = "#{self.id.to_s}_#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
      email = Notifier.create_message(person, self, id_and_code)
      email.add_message_id
      email.message_id = "<#{id_and_code}_#{email.message_id.gsub(/^</, '')}"
      Notifier.deliver(email)
    end
  end

  def send_to_group
    return unless group
    group.people.each do |person|
      if group.get_options_for(person).get_email and person.email.to_s.any? and person.email =~ VALID_EMAIL_ADDRESS
        send_to_person(person)
      end
    end
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
      "#{Setting.get(:url, :site)}people/view/#{person_id}#wall"
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
          msg << "Group page: #{Setting.get(:url, :site)}groups/view/#{group.id}\n"
        else
          msg << "To reply: #{reply_url}\n"
        end
      end
    elsif wall
      msg << "Your wall: #{Setting.get(:url, :site)}people/view/#{wall_id}#wall\n\n"
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
        msg << "#{Setting.get(:url, :site)}groups/toggle_email/#{group.id}?person_id=#{to_person.id}&code=#{group.get_options_for(to_person, true).code}"
        msg << '&return_to=/publications' if group.name == 'Publications'
      end
    else
      msg << "To stop these emails, go to your privacy page:\n#{Setting.get(:url, :site)}people/privacy"
    end
    msg
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
  
  # special time-limited address that relays a private message directly back to the sender
  def relay_address(name)
    email = person.name.downcase.scan(/[a-z]/).join('')
    email = email + person.id.to_s if Group.find_by_address(email)
    "\"#{name}\" <#{email + '@' + Site.current.host}>"
  end
  
  # generates security code
  def before_create
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end
  
  def flagged?
    log_items.count(:id, :conditions => "flagged_on is not null") > 0
  end
  
  def flagged_body
    flagged = body.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    FLAG_WORDS.each do |word|
      flagged.gsub! word, '<span class="flagged">\&</span>'
    end
    flagged
  end
  
  def can_see?(p)
    if group and group.private?
      p.member_of?(group)
    elsif group
      p.member_of?(group) or p.admin?(:manage_messages)
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
  
  def self.preview(attributes)
    msg = Message.new(attributes)
    returning Notifier.create_message(Person.new(:email => 'test@example.com'), msg).to_s do |preview|
      preview.gsub!(/\n/, "<br/>\n").gsub!(/http:\/\/[^\s<]+/, '<a href="\0">\0</a>')
    end
  end
  
  def self.create_with_attachments(attributes, files)
    message = Message.create(attributes.update(:dont_send => true))
    unless message.errors.any?
      files.select { |f| f && f.size > 0 }.each do |file|
        attachment = message.attachments.create(:name => File.split(file.original_filename).last, :content_type => file.content_type)
        if attachment.errors.any?
          attachment.errors.each_full { |e| message.errors.add_to_base(e) }
          return message
        else
          begin
            attachment.file = file
          rescue
            message.errors.add_to_base('Attachment could not be read.')
            return message
          end
        end
      end
      message.send_message
    end
    message
  end
end

module TMail
  class Mail
    # please don't mess with my message_id!
    def add_message_id( fqdn = nil )
      self.message_id ||= ::TMail::new_message_id(fqdn)
    end
  end
end
