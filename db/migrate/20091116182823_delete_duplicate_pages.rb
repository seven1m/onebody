class DeleteDuplicatePages < ActiveRecord::Migration
  def self.up
    Site.each do |site|
      while page = Page.where("(select count(*) from pages p2 where p2.path = pages.path and p2.id != pages.id and p2.site_id = #{site.id}) > 0").order('updated_at').first
        page.destroy_without_callbacks
      end
    end
  end

  def self.down
    # can't put them back, but no reason to hold up a revert to previous migrations
  end
end
