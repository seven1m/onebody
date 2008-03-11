# == Schema Information
# Schema version: 4
#
# Table name: feeds
#
#  id         :integer       not null, primary key
#  person_id  :integer       
#  group_id   :integer       
#  name       :string(255)   
#  url        :string(500)   
#  spec       :string(5)     
#  fetched_at :datetime      
#  created_at :datetime      
#  updated_at :datetime      
#  site_id    :integer       
#

require 'rss/0.9'
require 'rss/1.0'
require 'rss/2.0'
require 'atom'
require 'open-uri'

class Feed < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  attr_accessor :feed
  
  def fetch
    data = open(url).read
    if data =~ /<feed[^>]+atom/i # must be Atom
      @feed = Syndication::Atom::Parser.new.parse(data)
      update_attributes! :spec => 'atom', :name => @feed.title.txt, :fetched_at => Time.now
    else # must be some flavor of RSS
      @feed = Syndication::RSS::Parser.new.parse(data)
      update_attributes! :spec => 'rss', :name => @feed.channel.title, :fetched_at => Time.now
    end
  end
  
  def url
    @url = read_attribute :url
    if @url =~ /^file:/ and RAILS_ENV != 'production' # for testing
      @url = File.join(File.dirname(__FILE__), '../..', @url.gsub(/^file:\/\//, ''))
    end
    @url
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
