class GroupContactDetailsReport < Dossier::Report
  include ApplicationHelper
  include ReportsHelper

  def initialize(*args)
    super
    initialize_group
  end

  def formatted_title
    group_title('reports.reports.group_contact_details')
  end

  COLUMNS = %w(
    people.first_name
    people.last_name
    people.email
    people.mobile_phone
    families.home_phone
    families.address1
    families.address2
    families.city
    families.state
    families.zip
  ).freeze

  def sql
    Group
      .select(COLUMNS)
      .joins(memberships: { person: :family })
      .where('groups.id' => group_id)
      .to_sql
  end

  set_callback :execute, :after, :format_output

  def format_output
    # Headers - First 5 fields of sql, plus address label
    query_results
      .headers
      .push(I18n.t('reports.reports.group_contact_details.address'))
      .slice!(5..9)

    # Report Body - First five fields of output, compact address to one field.
    query_results
      .rows
      .map! { |x| x.take(5) << x.drop(5).compact.join(', ') }
      .sort_by! { |p| [p[1]] }
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
