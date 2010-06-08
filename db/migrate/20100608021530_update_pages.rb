class UpdatePages < ActiveRecord::Migration
  def self.up
    Site.each do |site|
      site.add_pages
      site.pages.all.each do |page|
        page.published = !Page::UNPUBLISHED_PAGES.include?(page.slug)
        page.save!
      end
    end
  end

  def self.down
  end
end
