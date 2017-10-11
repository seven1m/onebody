class GroupContactDetailsReport < ApplicationReport
  include ApplicationHelper
  include ReportsHelper

  def initialize(*args)
    super
    initialize_group
  end

  def formatted_title
    group_title('reports.reports.group_contact_details')
  end

  def headings
    [
      I18n.t('reports.reports.group_contact_details.columns.first_name'),
      I18n.t('reports.reports.group_contact_details.columns.last_name'),
      I18n.t('reports.reports.group_contact_details.columns.email_address'),
      I18n.t('reports.reports.group_contact_details.columns.mobile_phone'),
      I18n.t('reports.reports.group_contact_details.columns.home_phone'),
      I18n.t('reports.reports.group_contact_details.columns.address')
    ]
  end

  COLUMNS = [
    'people.first_name',
    'people.last_name',
    'people.email',
    'people.mobile_phone',
    'families.home_phone',
    "concat(families.address1, ', ', families.address2, ', ', " \
      "families.city, ', ', families.state, ', ', families.zip) as address"
  ].freeze

  def sql
    Group
      .select(COLUMNS)
      .joins(memberships: { person: :family })
      .where('groups.id' => group_id)
      .to_sql
  end

  def group_id
    options[:group_id]
  end

  def format_home_phone(value)
    format_phone(value)
  end

  def format_mobile_phone(value)
    format_phone(value, value)
  end
end
