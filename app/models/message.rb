require 'uri'

class Message < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :dependent => :destroy
  has_many :attachments
  
  validates_presence_of :person
  validates_presence_of :subject
  validates_length_of :subject, :minimum => 2
  validates_presence_of :body
  validates_length_of :body, :minimum => 2
  
  def top
    top = self
    while top.parent
      top = top.parent
    end
    return top
  end
  
  def before_save
    body.gsub! /http:\/\/.*?person_id=\d+&code=\d+/i, '--removed--'
    if Message.find_by_person_id_and_subject_and_body(person_id, subject, body, :conditions => 'created_at >= curdate()-1')
      errors.add_to_base 'already saved' # Notifier relies on this message (don't change it)
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
      Notifier.deliver_message(wall, self) if wall.email.to_s.any?
    end
  end

  def send_to_group
    return unless group
    group.people.each do |person|
      if group.get_options_for(person).get_email and person.email.to_s.any?
        Notifier.deliver_message(person, self)
      end
    end
  end
  
  def introduction
    if group and group.subscription
      ''
    elsif group
      "The following message was posted to the group \"#{group.name}\" by #{person.name}:\n"
    elsif wall
      "#{person.name} posted a message on your wall:\n"
    else
      "#{person.name} sent you the following message:\n"
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
          msg << "You may reply directly or at the following link: #{reply_url}\n"
        else
          msg << "To reply, please use the following link: #{reply_url}\n"
        end
      end
    elsif wall
      msg << WALL_DESCRIPTION + "\n\n"
      msg << "You can see your wall here: #{SITE_URL}people/view/#{wall_id}#wall\n\n"
      msg << "You can post a message to #{self.person.name_possessive} wall here: #{reply_url}\n"
    elsif share_email
      msg << "To keep your email address private, reply at: #{reply_url}\n"
    else
      msg << "To reply, please use the following link: #{reply_url}\n"
    end
    msg
  end
  
  def email_from
    if group
      "\"#{person.name} (via #{SITE_SIMPLE_URL})\" <#{group.address.to_s.any? ? (group.address + '@' + GROUP_ADDRESS_DOMAIN) : SYSTEM_NOREPLY_EMAIL}>"
    else  
      "\"#{person.name} (via #{SITE_SIMPLE_URL})\" <#{share_email ? person.email : SYSTEM_NOREPLY_EMAIL}>"
    end
  end

  def email_reply_to
    if group
      "\"#{group.name}\" <#{group.address.to_s.any? ? (group.address + '@' + GROUP_ADDRESS_DOMAIN) : SYSTEM_NOREPLY_EMAIL}>"
    else  
      "\"#{person.name}\" <#{share_email ? person.email : SYSTEM_NOREPLY_EMAIL}>"
    end
  end
end
