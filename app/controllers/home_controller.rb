class HomeController < ApplicationController
  def index
    friend_ids = @logged_in.friends.find(:all, :select => 'people.id').map { |f| f.id }.join(',')
    @items = LogItem.find(:all, :conditions => "model_name in ('Friendship', 'Picture', 'Verse', 'Recipe', 'Person', 'Message', 'Note', 'Comment') and person_id in (#{friend_ids})", :order => 'created_at desc', :limit => 25)
    @items = @items.select do |item|
      if item.object.is_a? Friendship
        item.object.person != item.person
      elsif item.object.is_a? Message
        (item.object.group and @logged_in.groups.include? item.object.group) \
          or (item.object.wall and @logged_in.friend? item.object.wall)
      else
        true
      end
    end
  end
end
