class AdminController < ApplicationController
  RECORD_LIMIT = 100
  
  def log
    @items = []
    Dir[File.join(RAILS_ROOT, 'db/photos/**/*.jpg')].select { |p| p =~ /\d+\.jpg/ }.each do |path|
      model_name = path.split('/')[-2].classify
      if ['Picture', 'Family', 'Groups', 'People', 'Recipe'].include? model_name
        model = eval(model_name)
        id = path.split('/').last.gsub(/\.jpg$/i, '').to_i
        record = model.find(id)
        @items << PhotoFile.new(path, record, File::Stat.new(path).mtime)
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
    @items.sort! { |a, b| b.updated_at.strftime('%Y%m%d%H%M%S') <=> a.updated_at.strftime('%Y%m%d%H%M%S') }
  end
end

PhotoFile = Struct.new('PhotoFile', :path, :record, :updated_at)