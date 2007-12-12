require 'active_record'
require 'digest/md5'

module Foo
  module Acts #:nodoc:
    module Password #:nodoc:

      def self.included(mod)
        mod.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_password
          class_eval do
            attr_reader :password
            def password=(unencrypted_password)
              @password = unencrypted_password
              if unencrypted_password
                self.encrypted_password = Digest::MD5.hexdigest(unencrypted_password)
              else
                self.encrypted_password = nil
              end
            end
            
            def change_password(new_password, new_password_confirmation)
              reload
              errors.clear
              self.password = new_password
              cself.password_confirmation = new_password_confirmation
              return self.save
            end
            
            extend Foo::Acts::Password::SingletonMethods
          end
        end
      end
      
      module SingletonMethods
        # if email and password match, returns a Person object
        # if email cannot be found, returns nil
        # if email is found but password doesn't match, returns false
        def authenticate(email, password, options={})
          unless options[:encrypted]
            password = Digest::MD5.hexdigest(password)
          end
          people = find_all_by_email(email)
          if people.length > 0
            # try each person until a password matches
            people.select { |p| p.encrypted_password }.each do |person|
              compare = options[:encrypted] ? Digest::MD5.hexdigest(person.encrypted_password + options[:salt].to_s) : person.encrypted_password
              return person if compare == password
            end
            return false
          else
            nil
          end
        end
      end

    end
  end
end

# reopen ActiveRecord and include all the above to make
# them available to all our models if they want it

ActiveRecord::Base.class_eval do
  include Foo::Acts::Password
end
