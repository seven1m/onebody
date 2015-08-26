class Import < ActiveRecord::Base
  belongs_to :person
  has_many :rows, class_name: 'ImportRow', dependent: :destroy
  scope_by_site_id

  validates :person, :filename, :status, presence: true
  validates :importable_type, inclusion: %w(Person)

  enum status: {
    pending:     0,
    parsing:     1,
    parsed:     10,
    matched:    20,
    previewing: 21,
    previewed:  30,
    active:     40,
    complete:   50,
    errored:    60
  }

  enum match_strategy: %w(
    by_id_only
    by_name
    by_contact_info
    by_name_or_contact_info
  )

  serialize :mappings, JSON

  after_update :preview_async, if: :should_preview?

  def progress
    number = self.class.statuses[status]
    (number / 50.0 * 100).ceil
  end

  def working?
    !%w(parsed previewed complete errored).include?(status)
  end

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

  def preview_async
    return if new_record? || !matched?
    self.status = :previewing
    self.save!
    ImportPreviewJob.perform_later(Site.current, id)
  end

  def execute_async
    return if new_record? || !previewed?
    self.status = :active
    self.save!
    ImportExecutionJob.perform_later(Site.current, id)
  end

  def should_preview?
    !new_record? && matched? && !Rails.env.test?
  end

  def destroyable?
    !%w(active complete).include?(status)
  end
end
