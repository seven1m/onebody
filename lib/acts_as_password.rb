require 'active_record'
require 'digest/md5'
require 'digest/sha1'

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
                self.encrypted_password = encrypt_second_pass(encrypt_first_pass(unencrypted_password))
              else
                self.encrypted_password = nil
              end
            end

            def change_password(new_password, new_password_confirmation)
              reload
              errors.clear
              self.password = new_password
              self.password_confirmation = new_password_confirmation
              return self.save
            end

            def encrypt_first_pass(pass)
              Digest::MD5.hexdigest(pass)
            end

            def encrypt_second_pass(pass)
              10.times { pass = Digest::SHA1.hexdigest(pass + salt) }
              return pass
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
          people = where(email: email).all
          if people.length > 0
            # try each person until a password matches
            people.each do |person|
              if person.encrypted_password
                compare = person.encrypt_second_pass(person.encrypt_first_pass(password.to_s))
                return person if person.encrypted_password == compare
              end
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
