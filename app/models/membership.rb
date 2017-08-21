class Membership < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'MembershipAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site

  validates_uniqueness_of :group_id, scope: %i(site_id person_id)

  scope_by_site_id

  scope :order_by_birthday, -> { order('ifnull(month(people.birthday), 99)') }
  scope :order_by_name,     -> { order('people.first_name, people.last_name') }
  scope :leaders,           -> { where(leader: true) }

  def family
    person.family
  end

  serialize :roles, Array
  validate :validate_roles

  def validate_roles
    if roles.any? { |r| r !~ /\A[a-z0-9 \-_\(\)]+\z/i }
      errors.add(:roles, :invalid)
    end
  end

  before_create :generate_security_code

  def generate_security_code
    begin
      code = rand(999_999)
      write_attribute :code, code
    end until code > 0
  end

  def self.sharing_columns
    columns.map(&:name).select { |c| c =~ /^share_/ }
  end

  def only_admin?
    person && group &&
      group.admin?(person, :exclude_global_admins) &&
      group.admins.length == 1
  end
end
