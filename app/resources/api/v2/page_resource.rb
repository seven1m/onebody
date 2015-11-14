module Api
  module V2
    class PageResource < OneBodyResource
      attributes :slug, :title, :body, :path, :published, :navigation,
                 :system, :raw

      has_one :parent, class_name: 'Page'
      has_many :children, class_name: 'Page'
    end
  end
end