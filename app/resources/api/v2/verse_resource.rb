module Api
  module V2
    class VerseResource < OneBodyResource
      attributes :reference, :text, :translation, :book, :chapter, :verse

      has_many :comments
    end
  end
end