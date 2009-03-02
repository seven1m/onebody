class EnsureSuperAdminsAreAdults < ActiveRecord::Migration
  def self.up
    Site.each do
      Setting.get(:access, :super_admins).map { |e| Person.find_by_email(e) }.each do |person|
        person.update_attribute(:child, false) if person
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert this migration.'
  end
end
