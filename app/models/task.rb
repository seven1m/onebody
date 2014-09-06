class Task < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'TaskAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site
  has_many :comments, as: :commentable, dependent: :destroy

  scope_by_site_id

  validates :name, :group_id, presence: true
end
