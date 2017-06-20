xml.instruct! :xml, version: '1.0'
xml.feed(xmlns: 'http://www.w3.org/2005/Atom') do |feed|
  feed.title "#{Setting.get(:name, :site)} News"
  feed.link news_url, href: news_url
  feed.updated @news_items.first.updated_at.xmlschema if @news_items.any?
  @news_items.each do |news_item|
    feed.entry do |entry|
      entry.id        news_item.id
      entry.title     news_item.title
      entry.content   news_item.body, type: 'html'
      entry.published news_item.created_at.xmlschema
      entry.updated   news_item.updated_at.xmlschema
      entry.link      url_for(news_item), href: url_for(news_item)
    end
  end
end
