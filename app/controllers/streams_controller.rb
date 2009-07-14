class StreamsController < ApplicationController

  def show
    @stream_items = @logged_in.stream_items(30)
    comment_people_ids = @stream_items.map { |s| s.context['comments'].to_a.map { |c| c['person_id'] } }.flatten
    @comment_people = Person.all(
      :conditions => ["id in (?)", comment_people_ids],
      :select => 'first_name, last_name, suffix, gender, id, family_id, updated_at'
    ).inject({}) { |h, p| h[p.id] = p; h }
  end

end
