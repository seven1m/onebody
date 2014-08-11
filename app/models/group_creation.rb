class GroupCreation
  class << self
    delegate :model_name, to: Group
  end

  def initialize(creator, attrs = {})
    @creator = creator
    @attrs = attrs
    @attrs[:address] = @attrs[:address].presence
    @attrs[:creator] = creator
  end

  delegate *%i[
    to_key
    errors
    name
    category
    description
    other_notes
    people
    leader_id
    meets
    location
    directions
    email
    address
    prayer
    pictures
    attendance
    approval_required_to_join
    private
    members_send
    link_code
    parents_of
    hidden
    photo
    updatable_by?
    id
    persisted?
    creator_name
    to_param
  ], to: :group

  def save
    return unless group.save
    if creator.admin?(:manage_groups)
      group.update_attribute(:approved, true)
    else
      group.memberships.create(person: creator, admin: true)
    end
  end

  def pending_approval?
    !creator.admin?(:manage_groups)
  end

  private

  attr_reader :creator, :attrs

  def group
    @group ||= Group.new(attrs)
  end
end