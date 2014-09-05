class Task < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'TaskAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  validates_presence_of :name, :group_id, :person_id
end
