class Import < ActiveRecord::Base
  belongs_to :person
  has_many :rows, class_name: 'ImportRow', dependent: :destroy
  scope_by_site_id

  validates :person, :filename, :status, presence: true
  validates :importable_type, inclusion: %w(Person)

  enum status: {
    pending:   0,
    parsed:   10,
    matched:  20,
    active:   30,
    complete: 40
  }

  enum match_strategy: %w(
    by_id_only
    by_name
    by_contact_info
    by_name_or_contact_info
  )

  serialize :mappings, JSON

  before_update :set_status_to_matched

  def parse_async(file:, strategy_name:)
    return if new_record?
    ImportParserJob.perform_later(Site.current, id, file.read, strategy_name)
  end

  def status_at_least?(desired)
    number = self.class.statuses[desired.to_s]
    fail 'unknown status' unless number
    self[:status] >= number
  end

  def mappable_attributes
    Person.importable_column_names
  end

  private

  def set_status_to_matched
    return unless status == 'parsed'
    return unless match_strategy_changed? && match_strategy
    self.status = 'matched'
  end
end
