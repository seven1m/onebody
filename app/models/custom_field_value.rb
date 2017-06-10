class CustomFieldValue < ActiveRecord::Base
  DATE_FORMAT_PATTERN = /\A\d{4}\-\d{2}\-\d{2}\z/
  DATE_FORMAT = '%Y-%m-%d'.freeze

  scope_by_site_id

  belongs_to :object, polymorphic: true
  belongs_to :field, class_name: 'CustomField'

  validate :validate_value_format

  def value=(v)
    self[:value] = case field.format
                   when 'date'
                     format_date_string(v)
                   else
                     v
                   end
  end

  private

  def validate_value_format
    case field.format
    when 'number'
      validate_number_value_format
    when 'boolean'
      validate_boolean_value_format
    when 'date'
      validate_date_value_format
    end
  end

  def validate_number_value_format
    return if value.to_s =~ /\A\d*\z/
    errors.add(:value, :invalid)
  end

  def validate_boolean_value_format
    return if value.blank? || %w(0 1).include?(value)
    errors.add(:value, :invalid)
  end

  def validate_date_value_format
    return if value.blank? || value.to_s =~ DATE_FORMAT_PATTERN
    errors.add(:value, :invalid)
  end

  def format_date_string(string)
    return unless string.present?
    if string =~ DATE_FORMAT_PATTERN
      string
    elsif (date = Date.parse_in_locale(string))
      date.strftime(DATE_FORMAT)
    else
      string
    end
  end
end
