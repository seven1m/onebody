require 'active_support/concern'

module Concerns
  module Person
    module Import
      extend ActiveSupport::Concern

      included do
        has_many :import_rows, dependent: :nullify
      end

      module ClassMethods
        def importable_column_names
          (
            Updater::PARAMS[:person].keys.flat_map { |k| expand_importable_column_name(k, ::Person) } +
            Updater::PARAMS[:family].keys.flat_map { |k| expand_importable_column_name("family_#{k}", ::Family) }
          ).map(&:to_s).uniq + ['id', 'family_id']
        end

        # expand 'share_' into ['share_address', 'share_home_phone', ...]
        def expand_importable_column_name(name, klass)
          return name unless name =~ /_\z/
          klass.columns.map(&:name).select { |c| c.to_s.index(name.to_s) == 0 }
        end
      end
    end
  end
end
