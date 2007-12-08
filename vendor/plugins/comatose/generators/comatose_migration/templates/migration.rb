module Comatose
  class Page < ActiveRecord::Base
    set_table_name 'comatose_pages'
    acts_as_versioned :if_changed => [:title, :slug, :keywords, :body]
  end
end

class <%= class_name %> < ActiveRecord::Migration

  # Schema for Comatose version 0.7+
  def self.up
    create_table :comatose_pages do |t|
      t.column "parent_id",   :integer
      t.column "full_path",   :text,   :default => ''
      t.column "title",       :string, :limit => 255
      t.column "slug",        :string, :limit => 255
      t.column "keywords",    :string, :limit => 255
      t.column "body",        :text
      t.column "filter_type", :string, :limit => 25, :default => "Textile"
      t.column "author",      :string, :limit => 255
      t.column "position",    :integer, :default => 0
      t.column "version",     :integer
      t.column "updated_on",  :datetime
      t.column "created_on",  :datetime
    end
    Comatose::Page.create_versioned_table
    puts "Creating the default 'Home Page'..."
    Comatose::Page.create( :title=>'Home Page', :body=>"h1. Welcome\n\nYour content goes here...", :author=>'System' )
  end

  def self.down
    Comatose::Page.drop_versioned_table
    drop_table :comatose_pages
  end

end
