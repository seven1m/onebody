class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.string :name, :host, :limit => 255
      t.timestamps
    end
    # create default site
    Site.current = default_site = Site.create(:name => 'Default', :host => '')
    raise 'Error creating default site with ID=1' if default_site.id != 1
    Site.sub_models.each do |model|
      add_column model.table_name, :site_id, :integer
      model.update_all "site_id = #{default_site.id}"
    end
  end

  def self.down
    drop_table :sites
    Site.sub_models.each do |model|
      remove_column model.table_name, :site_id
    end
  end
end
