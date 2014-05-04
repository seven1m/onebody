class UpdateAllStreamItems < ActiveRecord::Migration
  def self.up
    Site.each do
      Note.all.each        { |o| o.create_as_stream_item }
      Picture.all.each     { |o| o.create_as_stream_item }
      if defined?(Recipe)
        Recipe.all.each      { |o| o.create_as_stream_item }
      end
      Publication.all.each { |o| o.create_as_stream_item } if defined?(Publication)
      NewsItem.all.each    { |o| o.create_as_stream_item }
      Message.all(
        :conditions => 'person_id is not null and to_person_id is null and (wall_id is not null or group_id is not null)'
      ).each do |message|
        message.create_as_stream_item
      end
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
