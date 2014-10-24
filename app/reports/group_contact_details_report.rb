class GroupContactDetailsReport < Dossier::Report
  include ApplicationHelper
  include ReportsHelper

  def initialize(*args)
    super
    initialize_group
  end

  def formatted_title
    group_title ('reports.reports.group_contact_details')
  end

  def sql
   Group
      .select(:first_name,
      '`people`.`last_name` as last_name',
      '`people`.`email` as email',
      :mobile_phone,
      :home_phone,
      :address1,
      :address2,
      :city,
      :state,
      :zip)
      .joins(memberships: [{ person: :family }])
      .where(id: options[:group_id])
      .to_sql
  end

  set_callback :execute, :after, :format_output

  def format_output
    # Headers - First 5 fields of sql, plus address label
    @results
      .adapter_results
      .headers
      .push(I18n.t('reports.reports.group_contact_details.address'))
      .slice!(5..9)

    # Report Body - First five fields of output, compact address to one field.
    @results
      .adapter_results
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
