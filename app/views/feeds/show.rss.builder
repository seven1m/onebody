require 'digest/md5'

xml.instruct!

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do

    xml.title "#{@person.name_possessive} Recently Feed"
    xml.link people_url
    if @items.any?
      xml.pubDate CGI.rfc1123_date(@items.first.created_at.to_time)
    end
    xml.description "Friends and Group Members' Activity on #{Setting.get(:name, :site)}"

    @items.each do |item|
      xml.item do
        xml.title       item.name
        xml.link        people_url
        xml.description render(:partial => 'log_item', :locals => {:items => [item], :item => item})
        xml.pubDate     CGI.rfc1123_date(item.created_at.to_time)
        xml.guid        Digest::MD5.hexdigest("#{item.model_name}#{item.instance_id}#{item.created_at.to_time.to_s}")
        xml.author      item.person.name
      end
    end

  end
end
