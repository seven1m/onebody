xml.instruct! :xml, :version => "1.0" 
xml.feed(:xmlns => "http://www.w3.org/2005/Atom") do |feed|
  feed.title "#{Setting.get(:name, :site)} Publications"
  feed.link publications_url, :href => publications_url
  if @publications.any?
    feed.updated @publications.first.updated_at.xmlschema
  end
  @publications.each do |publication|
    feed.entry do |entry|
      entry.id        publication.id
      entry.title     publication.name
      entry.content   publication.description, :type => 'text'
      entry.published publication.created_at.xmlschema
      entry.updated   publication.updated_at.xmlschema
      entry.link      url_for(publication), :href => url_for(publication)
    end
  end
end
