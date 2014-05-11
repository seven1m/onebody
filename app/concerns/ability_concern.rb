require 'active_support/concern'

module AbilityConcern
  extend ActiveSupport::Concern

  included do
    scope :readable_by,
      -> user { authorizer.readable_by(user, self.all) }
  end
end
