class SimplifyPeopleGenders < ActiveRecord::Migration
  def self.up
    change_table :people do |t|
      t.boolean :child
    end
    Site.each do
      Person.all(:conditions => "gender in ('boy', 'Boy', 'girl', 'Girl')").each { |p| p.update_attribute(:child, true) }
      Person.update_all("gender = 'Male'",   "gender in ('m', 'male',   'man',   'Man',   'boy',  'Boy' )")
      Person.update_all("gender = 'Female'", "gender in ('f', 'female', 'woman', 'Woman', 'girl', 'Girl')")
    end
    Setting.destroy_all("name = 'Genders'")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert this migration.'
  end
end
