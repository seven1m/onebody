class CustomReport < ActiveRecord::Base
  include ActiveModel::Validations
  include Authority::Abilities
  self.authorizer_name = 'CustomReportAuthorizer'

  belongs_to :site

  scope_by_site_id

  validates :title, presence: true, length: { maximum: 50 }
  validates :body, presence: true
  validates :category,
            allow_nil: false,
            inclusion: { in: %w(1 2 3) }
  validates :filters, format: { with: /\A:\z/ }, allow_blank: true
  validate :filter_content

  def filter_content
    unless filters.nil?
      if filters.count(':') >= 2 &&
         filters.count(':') != filters.count(';') + 1
        errors.add(:filters,
                   I18n.t('reports.custom_reports.validation.filters'))
      end
    end
  end

  def data_set(category)
    case category
    when '1'
      data_type = :person_data
    when '2'
      data_type = :family_data
    when '3'
      data_type = :group_data
    end

    data = send(data_type, data)
    data
  end

  def person_data(_data)
    arr = create_where_arr(person_field_list)
    data_set = Person.where(arr).as_json(
               root: true, only: person_field_list,
               include: [{ family: { only: family_field_list } },
                         { groups: { only: group_field_list } },
                         { relationships: {
                           include: { related:
                             { only: first_last_list } },
                           only: name_list } },
                         { friendships: {
                           include: { friend:
                             { only: first_last_list } },
                           only: name_list } }])
    data_set
  end

  def family_data(_data)
    arr = create_where_arr(family_field_list)
    data_set = Family.where(arr).as_json(
               root: true, only: family_field_list,
               include: { people: {
                 include: { relationships: {
                   include: { related:
                     { only: first_last_list } },
                   only: name_list } },
                 only: person_field_list } })
    data_set
  end

  def group_data(_data)
    arr = create_where_arr(group_field_list)
    data_set = Group.where(arr).as_json(
               root: true, only: group_field_list,
               include: [{ people: { only: person_field_list } },
                         { prayer_requests: { only: prayer_request_list } },
                         { tasks: {
                           include: { person: { only: person_field_list } },
                           only: task_list } }
                        ])
    data_set
  end

  def create_where_arr(field_list)
    if filters.present?
      filter_arr = build_sql_array(field_list)
      arr = process_where_clause(filter_arr)
    else
      arr = '1=1'
    end
    arr
  end

  def process_where_clause(filter_arr)
    binds = {}
    where = ' '

    filter_arr.each_with_index do |param, index|
      where << param[0] + ' ' + param[1] + ' :' + param[0]
      where << ' and ' unless index == filter_arr.size - 1
      binds[param[0].to_sym] = param[2].to_s
    end

    arr = [where, binds]
    arr
  end

  def build_sql_array(field_list)
    sql_array = []
    filtery = filters.split(';').compact
    filtery.each do |f|
      (fld, bind) = f.strip.split(':')
      bind.gsub!('*', '%')
      # Make sure fieldname is valid. If not, throw away.
      if field_list.include?(fld.to_sym)
        bind.include?('%') ? operator = 'like' : operator = '='
        sql_array << [fld, operator, bind]
      end
    end
    sql_array
  end

  def person_field_list
    [:first_name,
     :last_name,
     :email,
     :alternate_email,
     :birthday,
     :business_category,
     :business_description,
     :business_email,
     :business_name,
     :business_phone,
     :business_website,
     :fax,
     :facebook_url,
     :gender,
     :mobile_phone,
     :suffix,
     :testimony,
     :twitter,
     :website,
     :work_phone]
  end

  def family_field_list
    [:name,
     :family_name,
     :address1,
     :address2,
     :city,
     :state,
     :zip,
     :country,
     :home_phone]
  end

  def group_field_list
    [:name,
     :description,
     :meets,
     :location,
     :directions,
     :other_notes,
     :category,
     :leader_id,
     :full_address]
  end

  def first_last_list
    [:first_name,
     :last_name]
  end

  def name_list
    :name
  end

  def prayer_request_list
    [:request,
     :answer,
     :answered_at]
  end

  def task_list
    [:name,
     :duedate,
     :completed]
  end
end
