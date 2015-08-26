class ImportPreview < ImportExecution
  def preview
    execute
  end

  private

  def status_before
    'matched'
  end

  def status_during
    'previewing'
  end

  def status_after
    'previewed'
  end

  def save_row(row)
    reset_preview_data(row)
    row.save
  end

  def reset_preview_data(row)
    row.person.restore_attributes if row.person
    row.family.restore_attributes if row.family
    row.person.family = nil if row.person.try(:family).try(:new_record?)
  end
end
