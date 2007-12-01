require 'open-uri'
require 'rss/0.9'
require 'rss/1.0'
require 'rss/2.0'
require 'rss/content'
require 'atom' # gem install atom

module Feeder
  class Feed
    attr_accessor :data, :spec, :title, :link, :updated, :ttl
    
    def initialize(url)
      raw = open(url).read
      spec = (data =~ /^.{5,100}xmlns=.[^'"\s]Atom/) ? :atom : :rss
      case spec
      when :atom
        data = Atom::Feed.new(data)
        title = data.title
        link = data.links.first.href rescue nil
        #ttl = ? # need to get from response header cache-control I think
      when :rss
        data = RSS::Parser.parse(data, false)
        title = data.channel.title
        link = data.channel.link
        ttl = data.channel.ttl
      end
    end
    
    def entries
      case spec
      when :atom
        data.entries.map do |entry|
          {
            :title => entry.title,
            :link => (entry.links.first.href rescue nil),
            :id => entry.id,
            :updated => entry.updated,
            :content => entry.content
          }
        end
      when :rss
        data.items.map do |item|
          {
            :title => item.title,
            :link => item.link,
            :id => item.id,
            :updated => item.pubDate,
            :content => item.content_encoded || item.description
          }
        end
      end
    end
    alias_method :items, :entries
  end
end

# to make content_encoded on ruby rss lib
module RSS
  class Rss
    install_ns(CONTENT_PREFIX, CONTENT_URI)
    class Channel
      class Item; include ContentModel; end
    end
  end
end