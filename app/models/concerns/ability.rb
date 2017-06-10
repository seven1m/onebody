require 'active_support/concern'

module Concerns
  module Ability
    extend ActiveSupport::Concern

    included do
      scope :readable_by,
            ->(user) { authorizer.readable_by(user, all) }
    end
  end
end
