class UpdateAllStreamItems < ActiveRecord::Migration
  def self.up
    Site.each do
      Note.all.each        { |o| o.create_as_stream_item }
      Picture.all.each     { |o| o.create_as_stream_item }
      Recipe.all.each      { |o| o.create_as_stream_item }
      Publication.all.each { |o| o.create_as_stream_item }
      NewsItem.all.each    { |o| o.create_as_stream_item }
      Verse.all.each do |verse|
        verse.people.each do |person|
          verse.create_as_stream_item(person, verse.created_at)
        end
      end
    end
  end

  def self.down
  end
end
