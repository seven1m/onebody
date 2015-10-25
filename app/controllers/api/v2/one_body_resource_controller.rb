module Api
  module V2
    class OneBodyResourceController < JSONAPI::ResourceController

      def initialize
        Site.current = Site.where(id: 1).first || raise(t('application.no_default_site'))
      end

    end
  end
end