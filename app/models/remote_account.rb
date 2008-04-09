class RemoteAccount < ActiveRecord::Base
  belongs_to :site
  belongs_to :person
  has_many :sync_instances
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  def site_uri
    case self.account_type
    when 'highrise'
      "http://#{token}:X@#{username}.highrisehq.com/"
    else
      raise 'Unknown remote account type'
    end
  end
  
  def update_remote_person(person)
    case self.account_type
    when 'highrise'
      update_remote_person_in_highrise(person)
    else
      raise 'Unknown remote account type'
    end
  end
  
  def update_remote_person_in_highrise(person)
    Highrise::Base.site = self.site_uri
    if sync = self.sync_instances.find_by_person_id(person.id)
      remote_person = Highrise::Person.find(sync.remote_id)
      { # from      => to
        :first_name => :first_name,
        :last_name  => :last_name,
        # TODO more attributes
      }.each do |from, to|
        remote_person[to] = person[from]
      end
      sync.save # update timestamp
    else
      # TODO Highrise::Person.create or new -- need to get remote_id and save it
      sync = self.sync_instances.create(
        :owner_id => Person.logged_in.id,
        :person_id => person.id,
        :remote_id => remote_id
      )
    end
  end
end
