require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_person_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :conditions => 'to_person_id is null', :dependent => :destroy
  has_many :attachments
  has_many :log_items, :foreign_key => 'instance_id', :conditions => "model_name = 'Message'"
  
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
    if Message.find_by_person_id_and_subject_and_body(record.person_id, record.subject, record.body, :conditions => 'created_at >= curdate()-1')
      record.errors.add_to_base 'already saved' # Notifier relies on this message (don't change it)
    end
    if record.subject =~ /Out of Office/i
      record.errors.add_to_base 'autoreply' # don't change!
    end
  end

  attr_accessor :dont_send
  
  def after_save
    return if dont_send
    return if created_at < (Time.now - 1.day) # Yikes! I almost resent every message in the system!
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
    if group
      #intro = "The following message was posted to the group \"#{group.name}\" by #{person.name}.\n"
      #if group.can_post?(to_person) and group.address.to_s.any?
      #  intro << "REPLIES GO TO THE ENTIRE GROUP!\n"
      #end
      #intro
      ''
    elsif wall
      "#{person.name} posted a message on your wall:\n#{'- ' * 24}\n"
    else
      #"#{person.name} sent you the following message:\n#{'- ' * 24}\n"
      ''
    end
  end
  
  def reply_url
    if group
      "#{SITE_URL}messages/view/#{self.id.to_s}"
    elsif wall
      "#{SITE_URL}people/view/#{person_id}#wall"
    else
      reply_subject = self.subject
      reply_subject = "RE: #{subject}" unless reply_subject =~ /^re:/i
      "#{SITE_URL}messages/send_email/#{self.person.id}?subject=#{URI.escape(reply_subject)}"
    end
  end
  
  def reply_instructions(to_person)
    msg = ''
    if group
      if group.can_post? to_person
        if group.address.to_s.any?
          msg << "Hit \"Reply to All\" to send a message to the group, or send to: #{group.address + '@' + GROUP_ADDRESS_DOMAINS.first}\n"
          msg << "Group page: #{SITE_URL}groups/view/#{group.id}\n"
        else
          msg << "To reply: #{reply_url}\n"
        end
      end
    elsif wall
      msg << "Your wall: #{SITE_URL}people/view/#{wall_id}#wall\n\n"
      msg << "#{self.person.name_possessive} wall: #{reply_url}\n"
    #elsif share_email? # not used anymore
    #  msg << "To keep your email address private, reply at: #{reply_url}\n"
    #else
    #  msg << "Reply here: #{reply_url}\n"
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
        msg << "#{SITE_URL}groups/toggle_email/#{group.id}?person_id=#{to_person.id}&code=#{group.get_options_for(to_person, true).code}"
        msg << '&return_to=/publications' if group.name == 'Publications'
      end
    else
      msg << "To stop these emails, go to your privacy page:\n#{SITE_URL}people/privacy"
    end
    msg
  end
  
  def email_from(to_person)
    if wall or not to_person.messages_enabled?
      "\"#{person.name}\" <#{SYSTEM_NOREPLY_EMAIL}>"
    elsif group
      relay_address("#{person.name} [#{group.name}]")
    else
      relay_address(person.name)
    end
  end

  def email_reply_to(to_person)
    if wall or not to_person.messages_enabled?
      "\"DO NOT REPLY\" <#{SYSTEM_NOREPLY_EMAIL}>"
    else
      relay_address(person.name)
    end
  end
  
  # special time-limited address that relays a private message directly back to the sender
  def relay_address(name)
    email = "#{person.first_name.downcase.scan(/[a-z]/).join('')}.#{id}.#{Digest::MD5.hexdigest(code.to_s)[0..5]}"
    "\"#{name}\" <#{email + '@' + GROUP_ADDRESS_DOMAINS.first}>"
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
end
