class StreamsController < ApplicationController

  def show
    @stream_items = @logged_in.stream_items(30)
    @person = @logged_in
    @family = @person.family
    @friends = @person.friends.all(:limit => MAX_FRIENDS_ON_PROFILE).select { |p| @logged_in.can_see?(p) }
    @sidebar_group_people = @person.random_sidebar_group_people.select { |p| @logged_in.can_see?(p) }
    @family_people = @person.family.visible_people
  end

end
