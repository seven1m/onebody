# == Schema Information
# Schema version: 1
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
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  validates_presence_of :person_id
  validates_presence_of :subject
  validates_length_of :subject, :minimum => 2
  validates_presence_of :body
  validates_length_of :body, :minimum => 2
  
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
  
  def after_create
    return if dont_send
    if group
      send_to_group
    elsif to
      Notifier.deliver_message(to, self) if to.email.to_s.any?
    elsif wall
      Notifier.deliver_message(wall, self) if wall.email.to_s.any? and wall.get_wall_email
    end
  end

  def send_to_group
    return unless group
    group.people.each do |person|
      if group.get_options_for(person).get_email and person.email.to_s.any? and person.email =~ VALID_EMAIL_ADDRESS
        Notifier.deliver_message(person, self)
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
    email = "#{person.first_name.downcase.scan(/[a-z]/).join('')}.#{id}.#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
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
    (group and p.groups.include? group) or # a person in the group
    ((not group or not group.private?) and p.admin?(:manage_messages)) or # admin of groups (still cannot see private groups)
    (wall and p.can_see? wall) or
    (to and to == p) or # to me
    (person == p) # from me
  end
end
