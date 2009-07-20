class AddTourPagesToSites < ActiveRecord::Migration
  def self.up
    Site.each do |site|
      site.add_pages
    end
  end

  def self.down
  end
end
