class Membership < ActiveRecord::Base

  include Authority::Abilities
  self.authorizer_name = 'MembershipAuthorizer'

  belongs_to :group
  belongs_to :person
  belongs_to :site

  validates_uniqueness_of :group_id, scope: [:site_id, :person_id]

  scope_by_site_id

  def family; person.family; end

  before_create :generate_security_code

  def generate_security_code
    begin
      code = rand(999999)
      write_attribute :code, code
    end until code > 0
  end

  def self.sharing_columns
    columns.map { |c| c.name }.select { |c| c =~ /^share_/ }
  end
end
