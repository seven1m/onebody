require 'ostruct'

class Search
  attr_accessor :name, :family_name,
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
                :select_family,
                :group_category,
                :group_select_option,
                :sort

  def initialize(params = {})
    source = params.delete(:source) || :person
    params.each do |key, val|
      send("#{key}=", val) if respond_to?("#{key}=")
    end
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

  def results
    execute!
    @scope
  end

  def count
    execute!
    @scope.count
  end

  def family_name=(name)
    self.name = name
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

  def execute!
    return if @executed
    not_deleted!
    business!
    testimony!
    order_by_params! || order_by_name!
    parental_consent!
    visible!
    name!
    group_category!
    gender!
    birthday!
    anniversary!
    address!
    phone!
    email!
    type!
    family_barcode_id!
    @executed = true
  end

  def where!(*args)
    @scope = @scope.where(*args)
  end

  def order!(*args)
    @scope = @scope.order(*args)
  end

  def not_deleted!
    where!(people: { deleted: false })
    where!(families: { deleted: false })
  end

  def business!
    return unless business
    where!("coalesce(people.business_name, '') != ''")
    order!('people.business_name')
  end

  def testimony!
    return unless testimony
    where!("coalesce(people.testimony, '') != ''")
  end

  SORT_PARAM_WHITELIST = %w(
    people.first_name
    people.last_name
    families.name
    families.last_name
  )

  def order_by_params!
    return if sort.blank?
    params = sort.split(',').map do |param|
      param_without_hyphen = param.sub(/\A\-/, '')
      return false unless SORT_PARAM_WHITELIST.include?(param_without_hyphen)
      "#{param_without_hyphen} #{param.start_with?('-') ? 'desc' : 'asc'}"
    end
    order!(*params)
  end

  def order_by_name!
    order!('LOWER(people.last_name), LOWER(people.first_name)')
  end

  def parental_consent!
    return if show_hidden_profiles?
    where!("(people.child = ? or coalesce(people.parental_consent, '') != '')", false)
  end

  def visible!
    return if show_hidden_profiles?
    where!(people: { visible: true, status: Person.statuses.values_at(:active, :pending) })
    where!(families: { visible: true })
  end

  def name!
    return unless name
    where!(
      "(concat(people.first_name, ' ', people.last_name) #{like} :full_name
       or (families.name #{like} :full_name)
       or (people.alias) #{like} :first_name
       or (people.first_name #{like} :first_name and people.last_name #{like} :last_name))
      ",
      full_name:  like_match(name),
      first_name: like_match(name.split.first, :after),
      last_name:  like_match(name.split.last, :after)
    )
  end

  def group_category!
    if group_select_option == '0'
      where!('groups.category != ? OR groups.category IS NULL', group_category) if group_category.present?
    elsif group_select_option == '1'
      where!('groups.category = ?', group_category) if group_category.present?
    end
  end

  def gender!
    where!(people: { gender: gender }) if gender.present?
  end

  def birthday!
    self.birthday ||= {}
    where!('extract( month from people.birthday) = ?', birthday[:month]) if birthday[:month].present?
    where!('extract( day from people.birthday)   = ?', birthday[:day])   if birthday[:day].present?
  end

  def anniversary!
    self.anniversary ||= {}
    where!('extract(month from people.anniversary) = ?', anniversary[:month]) if anniversary[:month].present?
    where!('extract(day from people.anniversary)   = ?', anniversary[:day])   if anniversary[:day].present?
  end

  def address!
    self.address ||= {}
    where!("families.city  #{like} ?", like_match(address[:city],  :after)) if address[:city].present?
    where!("families.state #{like} ?", like_match(address[:state], :after)) if address[:state].present?
    where!("families.zip   #{like} ?", like_match(address[:zip],   :after)) if address[:zip].present?
  end

  def phone!
    return unless Person.logged_in.admin?(:view_hidden_properties)
    where!('people.mobile_phone = :phone or
            people.work_phone   = :phone or
            families.home_phone = :phone', phone: phone.digits_only) if phone.present?
  end

  def email!
    return unless Person.logged_in.admin?(:view_hidden_properties)
    where!('people.email = :email or
            people.alternate_email = :email', email: email) if email.present?
  end

  def type!
    if %w(member staff deacon elder).include?(type)
      where!("people.#{type} = ?", true)
    elsif type.present?
      where!('people.custom_type = ?', type)
    end
  end

  def family_barcode_id!
    where!('families.barcode_id = :id or families.alternate_barcode_id = :id', id: family_barcode_id) if family_barcode_id
  end

  def show_hidden_profiles?
    ((show_hidden || select_person || select_family) && Person.logged_in.admin?(:view_hidden_profiles))
  end

  def like
    if @scope.connection.adapter_name == 'PostgreSQL'
      'ilike'
    else
      'like'
    end
  end

  def like_match(str, position = :both)
    str.to_s.dup.gsub(/[%_]/) { |x| '\\' + x }.tap do |s|
      s.insert(0, '%') if [:before, :both].include?(position)
      s << '%'         if [:after,  :both].include?(position)
    end
  end
end
