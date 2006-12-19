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
  
  def reply_url
    if group
      "#{SITE_URL}messages/view/#{self.id.to_s}"
    else
      reply_subject = self.subject
      reply_subject = "RE: #{subject}" unless reply_subject =~ /^re:/i
      "#{SITE_URL}messages/send_email/#{self.person.id}?subject=#{URI.escape(reply_subject)}"
    end
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
