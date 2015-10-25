module Api
  module V2
    class NewsItemResource < OneBodyResource
      attributes :title, :link, :body, :published, :active, :source, :sequence,
                 :expires_at

      has_one :person
    end
  end
end