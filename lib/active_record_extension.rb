module ActiveRecordExtension
  extend ActiveSupport::Concern

  # add your static(class) methods here
  module ClassMethods
    def safe_like(field, expression)
      t = arel_table
      where(t[field].matches(expression))
    end
  end
end

# include the extension
ActiveRecord::Base.send(:include, ActiveRecordExtension)
