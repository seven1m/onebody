class StreamsController < ApplicationController

  def show
    @stream_items = @logged_in.stream_items(30)
    # preselect people for comments in one query...
    comment_people_ids = @stream_items.map { |s| s.context['comments'].to_a.map { |c| c['person_id'] } }.flatten
    @comment_people = Person.all(
      :conditions => ["id in (?)", comment_people_ids],
      :select => 'first_name, last_name, suffix, gender, id, family_id, updated_at' # only what's needed
    ).inject({}) { |h, p| h[p.id] = p; h } # as a hash with id as the key
    @person = @logged_in
  end

end
