xml.instruct! :xml, :version => "1.0" 
xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
  feed.title "#{Setting.get(:name, :site)} Activity Feed"
  feed.link stream_url, :href => stream_url
  if @stream_items.any?
    feed.updated @stream_items.first.created_at.xmlschema
  end
  @stream_items.each do |stream_item|
    feed.entry do |entry|
      entry.id        stream_item.id
      entry.title     stream_item.title
      entry.content   stream_item_content(stream_item, :use_code), :type => 'html'
      entry.published stream_item.created_at.xmlschema
      entry.updated   stream_item.created_at.xmlschema
      entry.link      url_for(stream_item), :href => url_for(stream_item)
    end
  end
end
