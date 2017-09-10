class Import < ApplicationRecord
  belongs_to :person
  has_many :rows, class_name: 'ImportRow', dependent: :delete_all

  validates :person, :filename, :status, presence: true
  validates :importable_type, inclusion: %w(Person)

  scope_by_site_id

  scope :with_row_counts, -> {
    select(
      '*, ' \
      '(select count(*) from import_rows where site_id = imports.site_id and import_id = imports.id) as row_count, ' \
      '(select count(*) from import_rows where site_id = imports.site_id and import_id = imports.id and errored = 1) as row_error_count'
    )
  }

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

  def waiting?
    %w(parsed matched previewed complete errored).include?(status)
  end

  def working?
    %w(pending parsing previewing active).include?(status)
  end

  WORKING_TIMEOUT = 1.minute

  def working_timeout_expired?
    updated_at < WORKING_TIMEOUT.ago
  end

  def verify_working
    return if waiting? || !working_timeout_expired?
    preview_async if previewing?
    execute_async if active?
  end

  def parse_async(file:, strategy_name:)
    return if new_record?
    data = file.read
    update_attribute(:row_count, data.count("\n")) # a rough count -- will be improved once parsing is complete
    ImportParserJob.perform_later(Site.current, id, data, strategy_name)
  end

  def status_at_least?(desired)
    desired_number = self.class.statuses[desired.to_s]
    raise 'unknown status' unless desired_number
    actual_number = self.class.statuses[self[:status]]
    actual_number >= desired_number
  end

  def mappable_attributes
    Person.importable_column_names
  end

  def preview_async
    return if new_record? || !(matched? || previewing?)
    self.status = :previewing
    save!
    ImportPreviewJob.perform_later(Site.current, id)
  end

  def reset_and_preview_async
    rows.update_all(status: ImportRow.statuses['parsed'])
    preview_async
  end

  def execute_async
    return if new_record? || !(matched? || previewed? || active?)
    self.status = :active
    save!
    ImportExecutionJob.perform_later(Site.current, id)
  end

  def reset_and_execute_async
    rows.update_all(status: ImportRow.statuses['previewed'])
    execute_async
  end

  def as_json(*args)
    super.merge(
      completed_rows_in_stage: completed_rows_in_stage.size,
      progress: progress,
      row_progress: row_progress
    )
  end
end
