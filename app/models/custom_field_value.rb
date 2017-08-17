class CustomFieldValue < ActiveRecord::Base
  DATE_FORMAT_PATTERN = /\A\d{4}\-\d{2}\-\d{2}\z/
  DATE_FORMAT = '%Y-%m-%d'.freeze

  scope_by_site_id

  belongs_to :object, polymorphic: true
  belongs_to :field, class_name: 'CustomField'

  validate :validate_value_format
  validate :validate_label_lookup

  attr_accessor :label_lookup_failed

  def value=(v)
    if v.is_a?(Concerns::Person::Fields::LabelLookupFailure)
      self.label_lookup_failed = v.label
      return
    end
    self[:value] = case field.format
                   when 'date'
                     format_date_string(v)
                   when 'boolean'
                     format_boolean_string(v)
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

  def validate_label_lookup
    return unless label_lookup_failed
    errors.add(
      :value,
      I18n.t(
        'activerecord.errors.models.custom_field_value.option_not_found',
        label: label_lookup_failed
      )
    )
  end

  def format_date_string(string)
    return unless string.present?
    return if empty_date?(string)
    if string =~ DATE_FORMAT_PATTERN
      string
    elsif (date = Date.parse_in_locale(string))
      date.strftime(DATE_FORMAT)
    else
      string
    end
  end

  def empty_date?(date)
    date.to_s.gsub(%r{/|\-}, '').blank?
  end

  def format_boolean_string(string)
    return unless string.present?
    string =~ /\A(true|t|yes|y|1)\z/i ? '1' : '0'
  end
end
