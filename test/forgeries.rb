require 'faker'

module Forgeable
  def forge(association, attributes={}, foreign_key=nil)
    foreign_key ||= self.class.name.downcase + '_id'
    attributes[foreign_key] = self.id
    eval(association.to_s.classify).forge(attributes)
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
      create! forgery_defaults.merge(attributes)
    end
    
    def fake(symbol)
      case symbol
      when :word
        Faker::Lorem.words(1).join
      when :sentence, :paragraph
        Faker::Lorem.send(symbol)
      when :email
        Faker::Internet.send(symbol)
      else
        raise 'Unrecognized faker symbol.'
      end
    end
  end
end

%w(Person Recipe Note Picture Verse).each do |model|
  eval model
  eval "class #{model}; include Forgeable; end"
end

class Person
  def self.forge(attributes={})
    attributes.symbolize_keys!
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    attributes[:family] ||= Family.create!(:name => first_name + ' ' + last_name, :last_name => last_name)
    defaults = {:first_name => first_name, :last_name => last_name, :gender => 'Male', :visible_to_everyone => true, :visible => true, :can_sign_in => true, :full_access => true, :email => Faker::Internet.email, :encrypted_password => '5ebe2294ecd0e0f08eab7690d2a6ee69'}
    create! defaults.merge(attributes)
  end
  
  def forge_blog
    # must be set for the logger to correctly mark these entries
    Person.logged_in = self
    # 28 total - blog only shows 25
    7.times { self.forge(:pictures) }
    7.times { self.forge(:notes)    }
    7.times { self.forge(:recipes)  }
    7.times { self.verses << Verse.forge }
  end
end

class Recipe
  self.forgery_defaults = {:title => :word, :ingredients => :paragraph, :directions => :paragraph}
end

class Note
  self.forgery_defaults = {:title => :word, :body => :paragraph}
end

class Picture
  def self.forge(attributes={})
    photo_path = File.join(RAILS_ROOT, attributes.delete(:photo) || 'public/images/man.gif')
    pic = Picture.create! attributes
    pic.photo = File.open(photo_path)
    pic
  end
end

class Verse
  def self.forge(attributes={})
    verse = Verse.new(:text => Faker::Lorem.sentence)
    verse.write_attribute :reference, "#{Faker::Lorem.words(1).join} #{rand(25)}:#{rand(50)}"
    attributes.each do |attr, val|
      verse.send("#{attr}=", val) # will allow tag_list= to work
    end
    verse.save!
    verse
  end
end