module Api
  module V2
    class CommentResource < OneBodyResource
      attributes :text

      has_one :person
    end
  end
end