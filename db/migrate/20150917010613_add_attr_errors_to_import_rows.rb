class AddAttrErrorsToImportRows < ActiveRecord::Migration[4.2]
  def change
    add_column :import_rows, :attribute_errors, :text
    add_column :import_rows, :errored, :boolean, default: false

    ImportRow.reset_column_information

    reversible do |dir|
      puts "Updating rows..."
      Site.each do
        ImportRow.all.each do |row|
          dir.up do
            print '.'
            row.update_attribute(:errored, true) if row.error_reasons.present?
          end
          dir.down do
            print '.'
            row.update_attribute(:error_reasons, 'There was an error.') if row.errored?
          end
        end
      end
      puts
    end

    ImportRow.reset_column_information

    remove_column :import_rows, :error_reasons, :string, limit: 1000
  end
end
