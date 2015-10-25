module Api
  module V2
    class MessageResource < OneBodyResource
      attributes :subject, :body, :html_body

      has_one :group
      has_one :person
      has_one :to, class_name: 'Person'
      has_one :parent, class_name: 'Message'
      has_many :children, class_name: 'Message'
      has_many :attachments
    end
  end
end