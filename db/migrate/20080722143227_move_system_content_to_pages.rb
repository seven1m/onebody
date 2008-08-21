class MoveSystemContentToPages < ActiveRecord::Migration
  def self.up
    Site.each do |site|
      site.add_pages
    end
  end

  def self.down
    Site.each do
      Page.find_all_by_system(true).each { |p| p.update_attribute(:system, false); p.destroy }
    end
  end
end
