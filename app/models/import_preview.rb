class ImportPreview
  def initialize(import)
    @import = import
  end

  def preview
    return unless @import.matched?
    @import.update_attribute(:status, 'previewing')
    @import.rows.each do |row|
      if person = row.match_person
        attributes = row.import_attributes_as_hash(real_attributes: true)
        changes = Comparator.new(person, attributes).changes
        if changes.any?
          row.status = :updated
        else
          row.status = :unchanged
        end
      else
        row.status = :created
      end
      row.save
    end
    @import.update_attribute(:status, 'previewed')
  end
end
