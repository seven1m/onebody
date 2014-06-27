class SetChildForAllPeople < ActiveRecord::Migration
  def change
    Site.each do
      min_age = Setting.get(:system, :adult_age).to_i
      Person.find_each do |person|
        person.child = !person.at_least?(min_age) if person.birthday
        person.save(validate: false)
      end
    end
  end
end
