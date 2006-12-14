require 'uri'

class Message < ActiveRecord::Base
  belongs_to :group
  belongs_to :person
  belongs_to :wall, :class_name => 'Person', :foreign_key => 'wall_id'
  belongs_to :to, :class_name => 'Person', :foreign_key => 'to_id'
  belongs_to :parent, :class_name => 'Message', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Message', :foreign_key => 'parent_id', :dependent => :destroy
  
  validates_presence_of :person
  validates_presence_of :body
  validates_length_of :body, :minimum => 1
  
  def top
    top = self
    while top.parent
      top = top.parent
    end
    return top
  end
  
  def after_save
    if group
      if group.linked?
        tos = group.memberships.find_all_by_get_email(true).map { |m| m.person }
      else
        tos = group.people
        tos = tos.select do |person|
          options = group.get_options_for(person)
          options.nil? or options.get_email
        end
      end
      tos.each do |to|
        Notifier.deliver_message(to, self) if to.email
      end
    elsif to
      Notifier.deliver_message(to, self) if to.email
    elsif wall
      Notifier.deliver_message(wall, self) if wall.email
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
end
