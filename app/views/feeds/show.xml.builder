xml.instruct! :xml, :version=>"1.0" 
xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
  feed.title "#{@person.name_possessive} Activity Feed"
  feed.link  people_url, :href => people_url
  for item in @items do
    feed.entry do |entry|
      entry.id      item.id
      entry.title   item.name
      entry.content render(:partial => 'log_item', :locals => {:items => [item], :item => item}), :type => 'html'
      entry.updated item.created_at
      entry.link    url_for(item.object), :href => url_for(item.object)
    end
  end
end
