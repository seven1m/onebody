class Import < ActiveRecord::Base
  belongs_to :person
  has_many :rows, class_name: 'ImportRow', dependent: :delete_all

  validates :person, :filename, :status, presence: true
  validates :importable_type, inclusion: %w(Person)

  enum status: {
    pending:     0,
    parsing:     1,
    parsed:     30,
    matched:    31,
    previewing: 32,
    previewed:  60,
    active:     61,
    complete:   100,
    errored:    101
  }

  enum match_strategy: %w(
    by_id_only
    by_name
    by_contact_info
    by_name_or_contact_info
  )

  serialize :mappings, JSON

  include FlagShihTzu

  has_flags \
    1 => :create_as_active,
    2 => :overwrite_changed_emails

  attr_accessor :dont_preview

  after_update :preview_async, if: :should_preview?

  def progress
    self.class.statuses[status]
  end

  def row_progress
    return 0 if row_count.to_i == 0
    (completed_rows_in_stage.count * 100 / row_count).round
  end

  def completed_rows_in_stage
    stage = {
      'parsing'    => 'parsed',
      'parsed'     => 'parsed',
      'previewing' => 'previewed',
      'previewed'  => 'previewed',
      'active'     => 'imported',
      'complete'   => 'imported'
    }[status]
    return rows.none if stage.nil?
    rows.send(stage)
  end

  def working?
    !%w(parsed previewed complete errored).include?(status)
  end

  def parse_async(file:, strategy_name:)
    return if new_record?
    data = file.read
    update_attribute(:row_count, data.count("\n")) # a rough count -- will be improved once parsing is complete
    ImportParserJob.perform_later(Site.current, id, data, strategy_name)
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
    return if new_record? || !ready_to_execute?
    self.status = :active
    self.save!
    ImportExecutionJob.perform_later(Site.current, id)
  end

  def ready_to_execute?
    previewed? || (dont_preview && matched?)
  end

  def should_preview?
    !new_record? && matched? && !dont_preview && !Rails.env.test?
  end

  def as_json(*args)
    super.merge(
      completed_rows_in_stage: completed_rows_in_stage.size,
      progress: progress,
      row_progress: row_progress
    )
  end
end
