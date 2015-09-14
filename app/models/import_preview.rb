class ImportPreview < ImportExecution
  def preview
    execute
  end

  private

  def set_completed_at?
    false
  end

  def status_before
    'previewing'
  end

  def row_status_before
    'parsed'
  end

  def status_after
    'previewed'
  end

  def save_row(row)
    record_changes(row, :changes)
    reset_preview_data(row)
    row.status = :previewed
    row.save
  end

  def reset_preview_data(row)
    row.person.restore_attributes if row.person && !row.person.new_record?
    row.family.restore_attributes if row.family && !row.family.new_record?
    row.person.family = nil if row.person && row.person.family && row.person.family.new_record?
    row.person = nil if row.person && row.person.new_record?
    row.family = nil if row.family && row.family.new_record?
  end
end
