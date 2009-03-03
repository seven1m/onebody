require 'faker'

module Forgeable
  def forge(association, attributes={}, foreign_key=nil)
    foreign_key ||= self.class.name.downcase + '_id'
    attributes.merge!(foreign_key => self.id)
    eval(association.to_s.classify).forge(attributes)
  end
  
  def forge_photo(photo=true)
    if photo.is_a?(String)
      self.photo = File.open(photo)
    else
      self.photo = File.open(RAILS_ROOT + '/test/fixtures/files/image.jpg')
    end
  end
  
  def forge_file(file=true)
    if file.is_a?(String)
      self.file = File.open(file)
    else
      self.file = ActionController::TestUploadedFile.new(File.dirname(__FILE__) + '/fixtures/files/attachment.pdf', nil, false)
    end
  end
  
  def self.included(mod)
    mod.extend(ClassMethods)
    mod.class_eval <<-END
      @@forgery_defaults = {}
      
      def self.forgery_defaults=(defaults)
        class_eval do
          @@forgery_defaults = defaults
        end
      end

      def self.forgery_defaults
        defaults = {}
        @@forgery_defaults.each do |key, val|
          if val.respond_to? :call
            defaults[key] = val.call
          elsif val.is_a? Symbol
            defaults[key] = self.fake(val)
          else
            defaults[key] = val
          end
        end
        defaults
      end
    END
  end
  
  module ClassMethods
    
    def forge(attributes={})
      attributes.symbolize_keys!
      attributes = forgery_defaults.merge(attributes)
      photo = attributes.delete(:photo)
      file = attributes.delete(:file)
      begin
        returning create!(attributes) do |obj|
          obj.forge_photo(photo) if photo
          obj.forge_file(file)   if file
        end
      rescue ActiveRecord::RecordInvalid => e
        if e.message =~ /^Validation failed: (.+) has already been taken/
          attributes[$1.downcase.to_sym] << 'a'
          retry
        else
          puts e.message
        end
      end
    end
    
    def fake(symbol)
      case symbol
      when :word
        Faker::Lorem.words(1).join
      when :sentence, :paragraph
        Faker::Lorem.send(symbol)
      when :email
        Faker::Internet.send(symbol)
      when :name
        "#{fake :first_name} #{fake :last_name}"
      when :first_name, :last_name
        Faker::Name.send(symbol)
      when :link
        "http://#{Faker::Internet.domain_name}"
      else
        raise 'Unrecognized faker symbol.'
      end
    end
    
  end
end

%w(Family Person Recipe Note Picture Verse Group Album Publication Tag NewsItem Comment PrayerRequest).each do |model|
  eval model
  eval "class #{model}; include Forgeable; end"
end

class Person
  def self.forge(attributes={})
    attributes.symbolize_keys!
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    photo = attributes.delete(:photo)
    attributes[:family] ||= Family.forge(:name => "#{first_name} #{last_name}", :last_name => last_name)
    defaults = {:first_name => first_name, :last_name => last_name, :gender => 'Male', :visible_to_everyone => true, :visible => true, :can_sign_in => true, :full_access => true, :email => Faker::Internet.email, :encrypted_password => '5ebe2294ecd0e0f08eab7690d2a6ee69', :child => false}
    person = create!(defaults.merge(attributes))
    person.forge_photo if photo
    person
  end
  
  def forge_blog
    # must be set for the logger to correctly mark these entries
    Person.logged_in = self
    # 26 total - blog only shows 25
    1.times  { self.forge(:pictures) }
    10.times { self.forge(:notes)    }
    10.times { self.forge(:recipes)  }
    5.times  { self.verses << Verse.forge; self.save }
  end
end

class Group
  self.forgery_defaults = {:name => :word, :category => :word, :approved => true}
end

class Family
  self.forgery_defaults = {:name => :name, :last_name => :last_name}
end

class Recipe
  self.forgery_defaults = {:title => :word, :ingredients => :paragraph, :directions => :paragraph}
end

class Note
  self.forgery_defaults = {:title => :word, :body => :paragraph}
end

class Picture
  self.forgery_defaults = {:photo => true, :album_id => Proc.new { Album.forge.id }}
end

class Album
  self.forgery_defaults = {:name => :word}
end

class Publication
  self.forgery_defaults = {:name => :word, :description => :paragraph, :file => true}
end

class NewsItem
  self.forgery_defaults = {:title => :sentence, :link => :link}
end

class Verse
  def self.forge(attributes={})
    returning Verse.find("#{Verse::BOOKS.rand} #{rand(25)+1}:#{rand(50)+1}") do |verse|
      attributes.each do |attr, val|
        verse.send("#{attr}=", val) # will allow tag_list= to work
      end
      verse.save!
    end
  end
end

class Tag
  self.forgery_defaults = {:name => :word}
end

class Comment
  self.forgery_defaults = {:text => :sentence}
end

class PrayerRequest
  self.forgery_defaults = {:request => :sentence, :answer => :sentence, :answered_at => Time.now}
end
