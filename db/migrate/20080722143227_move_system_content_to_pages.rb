class MoveSystemContentToPages < ActiveRecord::Migration
  def self.up
    Site.each do
      Dir[File.dirname(__FILE__) + "/20080722143227_move_system_content_to_pages/**/index.html"].each do |filename|
        html = File.read(filename)
        path, filename = filename.split('pages/').last.split('/')
        pub = nav = path != 'system'
        unless Page.find_by_path(path)
          Page.create!(:slug => path, :title => path.titleize, :body => html, :system => true, :navigation => nav, :published => pub)
        end
      end
      Dir[File.dirname(__FILE__) + "/20080722143227_move_system_content_to_pages/**/*.html"].each do |filename|
        next if filename =~ /index\.html$/
        html = File.read(filename)
        path, filename = filename.split('pages/').last.split('/')
        slug = filename.split('.').first
        nav = path != 'system'
        parent = Page.find_by_path(path)
        unless parent.children.find_by_slug(slug)
          parent.children.create!(:slug => slug, :title => slug.titleize, :body => html, :system => true, :navigation => nav, :published => true)
        end
      end
      unless Page.find_by_path('home')
        Page.create!(:slug => 'home', :title => 'Home', :body => 'Congratulations! OneBody is up and running.', :system => true)
      end
    end
    require 'fileutils'
    FileUtils.rm_rf(Rails.root + "/cache/views/pages")
  end

  def self.down
    Site.each do
      Page.find_all_by_system(true).each { |p| p.update_attribute(:system, false); p.destroy }
    end
  end
end
