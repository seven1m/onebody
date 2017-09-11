class Task < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = 'TaskAuthorizer'

  include Concerns::DateWriter

  acts_as_list scope: :group

  belongs_to :group
  belongs_to :person, optional: true
  has_many :comments, as: :commentable, dependent: :destroy

  scope_by_site_id

  scope :incomplete, -> { where(completed: false) }

  validates :name, :group_id, presence: true

  after_save :update_counter_cache
  after_destroy :update_counter_cache
  def person_id_or_all=(id)
    self.person_id = (self.group_scope = (id == 'All')) ? nil : id
    id
  end

  def person_id_or_all
    group_scope ? 'All' : person_id
  end

  def update_counter_cache
    Person.find([].append(group_scope && group.memberships.pluck(:person_id)).flatten
                  .append(person_id).reject(&:!)).each do |assigned|
      assigned.update_attribute(:incomplete_tasks_count, assigned.tasks.incomplete.count)
    end
  end
  date_writer :duedate
end
