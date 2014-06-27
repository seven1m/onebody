class FixCategories < ActiveRecord::Migration
  def change
    Site.each do
      Group.where(category: '!').update_all(category: '')
      Person.where(business_category: '!').update_all(business_category: '')
    end
  end
end
