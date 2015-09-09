require 'ostruct'

class PersonSearch < Search
  attr_accessor :source,
                :quick_name, :name,
                :gender,
                :address,
                :birthday, :anniversary,
                :type,
                :family_barcode_id,
                :business,
                :testimony,
                :phone,
                :email,
                :show_hidden,
                :select_person,
                :group_category,
                :group_select_option

  def initialize(params = {})
    self.source = params.delete(:source) || :person
    super
  end

  def build_scope
    if source == :person
      if group_category.present?
        @scope = Person.eager_load(:family, :groups) # for left outer join for groups
      else
        @scope = Person.joins(:family)
      end
    elsif source == :family
      @scope = Family.includes(:people)
    end
  end

  def birthday(key = nil)
    if key
      @birthday.try(:[], key).to_i
    else
      @birthday
    end
  end

  def anniversary(key = nil)
    if key
      @anniversary.try(:[], key).to_i
    else
      @anniversary
    end
  end

  def address(key = nil)
    if key
      @address.try(:[], key)
    else
      @address
    end
  end

  private

  def execute
    return if @executed
    filter_not_deleted
    filter_business
    filter_testimony
    order_by_name
    filter_parental_consent
    filter_visible
    filter_name
    filter_group_category
    filter_gender
    filter_birthday
    filter_anniversary
    filter_address
    filter_phone
    filter_email
    filter_type
    filter_family_barcode_id
    @executed = true
  end

  def filter_not_deleted
    where(people: { deleted: false })
    where(families: { deleted: false })
  end

  def filter_business
    return unless business
    where("coalesce(people.business_name, '') != ''")
    order('people.business_name')
  end

  def filter_testimony
    return unless testimony
    where("coalesce(people.testimony, '') != ''")
  end

  def order_by_name
    order('LOWER(people.last_name), LOWER(people.first_name)')
  end

  def filter_parental_consent
    return if show_hidden_profiles?
    where("(people.child = ? or coalesce(people.parental_consent, '') != '')", false)
  end

  def filter_visible
    return if show_hidden_profiles?
    where(people: { visible: true, status: Person.statuses.values_at(:active, :pending) })
    where(families: { visible: true })
  end

  def filter_name
    self.name ||= quick_name
    return unless name
    (first, last) = name.split(nil, 2)
    where(
      "(concat(people.first_name, ' ', people.last_name) #{like} :name
       or (families.name = :name_bare)
       or (families.name = :name_bare_and)
       or (people.first_name #{like} :first_name and people.last_name #{like} :last_name))
      ",
      name_bare:     name,
      name_bare_and: name.sub(/ and /, ' & '),
      name:          like_match(name),
      first_name:    like_match(first, :after),
      last_name:     like_match(last, :after)
    )
  end

  def filter_group_category
    if group_select_option == '0'
      where('groups.category != ? OR groups.category IS NULL', group_category) if group_category.present?
    elsif group_select_option == '1'
      where('groups.category = ?', group_category) if group_category.present?
    end
  end

  def filter_gender
    where(people: { gender: gender }) if gender.present?
  end

  def filter_birthday
    self.birthday ||= {}
    where('extract( month from people.birthday) = ?', birthday[:month]) if birthday[:month].present?
    where('extract( day from people.birthday)   = ?', birthday[:day])   if birthday[:day].present?
  end

  def filter_anniversary
    self.anniversary ||= {}
    where('extract(month from people.anniversary) = ?', anniversary[:month]) if anniversary[:month].present?
    where('extract(day from people.anniversary)   = ?', anniversary[:day])   if anniversary[:day].present?
  end

  def filter_address
    self.address ||= {}
    where("families.city  #{like} ?", like_match(address[:city],  :after)) if address[:city].present?
    where("families.state #{like} ?", like_match(address[:state], :after)) if address[:state].present?
    where("families.zip   #{like} ?", like_match(address[:zip],   :after)) if address[:zip].present?
  end

  def filter_phone
    return unless Person.logged_in.admin?(:view_hidden_properties)
    where('people.mobile_phone = :phone or
            people.work_phone   = :phone or
            families.home_phone = :phone', phone: phone.digits_only) if phone.present?
  end

  def filter_email
    return unless Person.logged_in.admin?(:view_hidden_properties)
    where('people.email = :email or
            people.alternate_email = :email', email: email) if email.present?
  end

  def filter_type
    if %w(member staff deacon elder).include?(type)
      where("people.#{type} = ?", true)
    elsif type.present?
      where('people.custom_type = ?', type)
    end
  end

  def filter_family_barcode_id
    where('families.barcode_id = :id or families.alternate_barcode_id = :id', id: family_barcode_id) if family_barcode_id
  end

  def show_hidden_profiles?
    ((show_hidden || select_person) && Person.logged_in.admin?(:view_hidden_profiles))
  end
end
