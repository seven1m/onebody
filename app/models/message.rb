require 'uri'
require 'digest/md5'

class Message < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_person_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :dependent => :destroy
  has_many :attachments
  
  validates_presence_of :person_id
  validates_presence_of :subject
  validates_length_of :subject, :minimum => 2
  validates_presence_of :body
  validates_length_of :body, :minimum => 2
  
  acts_as_logger LogItem
  
  def name
    if self.to
      "Private Message to #{to.name}"
    elsif wall
      "Post on #{wall.name_possessive} Wall"
    elsif parent
      "Reply to \"#{parent.subject}\" in Group #{top.group.name}"
    else
      "Message \"#{subject}\" in Group #{group.name}"
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
    if group and group.subscription
      ''
    elsif group
      #intro = "The following message was posted to the group \"#{group.name}\" by #{person.name}.\n"
      #if group.can_post?(to_person) and group.address.to_s.any?
      #  intro << "REPLIES GO TO THE ENTIRE GROUP!\n"
      #end
      #intro
      ''
    elsif wall
      "#{person.name} posted a message on your wall:\n#{'- ' * 24}\n"
    else
      "#{person.name} sent you the following message:\n#{'- ' * 24}\n"
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
  
  def reply_instructions(person)
    msg = ''
    if group and group.subscription
      ''
    elsif group
      if group.can_post? person
        if group.address.to_s.any?
          msg << "Group email: #{group.address + '@' + GROUP_ADDRESS_DOMAINS.first}\n"
          msg << "Message address: #{reply_url}\n"
        else
          msg << "To reply: #{reply_url}\n"
        end
      end
    elsif wall
      msg << WALL_DESCRIPTION + "\n\n"
      msg << "Your wall: #{SITE_URL}people/view/#{wall_id}#wall\n\n"
      msg << "#{self.person.name_possessive} wall: #{reply_url}\n"
    elsif share_email? # not used anymore
      msg << "To keep your email address private, reply at: #{reply_url}\n"
    else
      msg << "Reply here: #{reply_url}\n"
    end
    msg
  end
  
  def email_from
    if group
      "\"#{person.name}\" <#{group.address.to_s.any? ? (group.address + '@' + GROUP_ADDRESS_DOMAINS.first) : SYSTEM_NOREPLY_EMAIL}>"
    else  
      "\"#{person.name}\" <#{share_email? ? person.email : SYSTEM_NOREPLY_EMAIL}>"
    end
  end

  def email_reply_to
    if group
      membership = group.get_options_for(person, true)
      # sure, this isn't fort knox... it's just to protect that little code a tiny bit
      # not that you can do much with that code anyway (except turn on/off somebody's group email)
      email = "#{person.first_name.downcase.scan(/[a-z]/).join('')}.#{membership.id}.#{Digest::MD5.hexdigest(membership.code.to_s)[0..5]}"
      "\"#{person.name}\" <#{email + '@' + GROUP_ADDRESS_DOMAINS.first}>"
    elsif share_email?
      "\"#{person.name}\" <#{person.email}>"
    else
      "\"DO NOT REPLY\" <#{SYSTEM_NOREPLY_EMAIL}>"
    end
  end
end
