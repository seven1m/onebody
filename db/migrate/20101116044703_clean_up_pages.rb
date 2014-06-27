class CleanUpPages < ActiveRecord::Migration
  def self.up
    Site.each do
      Page.where("path in ('home', 'system')").update_all('system = 0')
    end
  end

  def self.down
  end
end
