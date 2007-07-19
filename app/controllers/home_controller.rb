class HomeController < ApplicationController
  def index
    friend_ids = @logged_in.friends.find(:all, :select => 'people.id').map { |f| f.id }.join(',')
    @items = LogItem.find(:all, :conditions => "model_name in ('Friendship', 'Picture', 'Verse', 'Recipe', 'Person', 'Message', 'Group', 'Note') and person_id in (#{friend_ids})", :order => 'created_at desc', :limit => 25)
  end
end
