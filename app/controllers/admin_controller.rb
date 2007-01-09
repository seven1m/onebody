class AdminController < ApplicationController
  before_filter :only_admins
  
  RECORD_LIMIT = 50
  
  def log
    @items = []
    filenames = Dir[File.join(RAILS_ROOT, 'db/photos/**/*.jpg')].select { |p| p =~ /\d+\.jpg/ }.sort{ |a, b| File.mtime(b) <=> File.mtime(a)}
    filenames[0...RECORD_LIMIT].each do |path|
      model_name = path.split('/')[-2].classify
      if ['Picture', 'Family', 'Group', 'Person', 'Recipe'].include? model_name
        model = eval(model_name)
        id = path.split('/').last.gsub(/\.jpg$/i, '').to_i
        if record = model.find(id) rescue nil
          @items << PhotoFile.new(path, record, File::Stat.new(path).mtime)
        end
      end
    end
    @items << Person.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    #@items << Family.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Group.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Verse.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Comment.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Message.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    #@items << Picture.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Recipe.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items << Tag.find(:all, :limit => RECORD_LIMIT, :order => 'updated_at desc')
    @items.flatten!
    @items = @items.select { |i| i.updated_at }
    @items.sort! { |a, b| b.updated_at.strftime('%Y%m%d%H%M%S') <=> a.updated_at.strftime('%Y%m%d%H%M%S') }
    @items = @items[0..100]
  end

  def updates
    @updates = Update.find_all_by_complete(params[:complete] == 'true')
  end
  
  def toggle_complete
    @update = Update.find params[:id]
    @update.toggle! :complete
    redirect_to :action => 'updates'
  end
end

PhotoFile = Struct.new('PhotoFile', :path, :record, :updated_at)
