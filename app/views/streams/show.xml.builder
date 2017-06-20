xml.instruct! :xml, version: '1.0'
xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do |feed|
  feed.title "#{Setting.get(:name, :site)} Activity Feed"
  feed.id    stream_url
  feed.link  nil, href: stream_url
  feed.updated @stream_items.first.created_at.xmlschema if @stream_items.any?
  @stream_items.each do |stream_item|
    feed.entry do |entry|
      entry.id        stream_item_url(stream_item) + '#' + stream_item.id.to_s
      entry.title     stream_item.title
      entry.author do |author|
        if stream_item.person
          author.name stream_item.person.name
          author.uri  person_url(stream_item.person)
        else
          author.name 'Admin'
        end
      end
      entry.content   stream_item_content(stream_item, :use_code), type: 'html'
      entry.published stream_item.created_at.xmlschema
      entry.updated   stream_item.created_at.xmlschema
      entry.link      nil, href: stream_item_url(stream_item)
    end
  end
end
