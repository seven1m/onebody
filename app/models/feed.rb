require 'syndication/rss'
require 'syndication/atom'
require 'syndication/content'
require 'open-uri'

class Feed < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  
  def fetch
    data = open(url).read
    if data =~ /<feed[^>]+atom/i # must be Atom
      @feed = Syndication::Atom::Parser.new.parse(data)
      update_attributes :spec => 'atom', :name => @feed.title.txt, :fetched_at => Time.now
    else # must be some flavor of RSS
      @feed = Syndication::RSS::Parser.new.parse(data)
      update_attributes :spec => 'rss', :name => @feed.channel.title, :fetched_at => Time.now
    end
  end

  def entries
    fetch unless @feed
    case spec
    when 'atom'
      entries.map do |entry|
        {
          :title => entry.title.txt,
          :body => entry.content,
          :datetime => entry.published,
          :author => (entry.author.name rescue nil),
          :link => entry.links.select { |l| l.rel.downcase == 'alternate' }.first.href
        }
      end
    when 'rss'
      items.map do |item|
        {
          :title => item.title,
          :body => item.content_decoded || item.description,
          :datetime => item.pubdate,
          :author => (entry.author.name rescue nil),
          :link => item.link
        }
      end
    end
  end

end
