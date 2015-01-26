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
                :select_family

  def initialize(params={})
    source = params.delete(:source) || :person
    params.each do |key, val|
      self.send("#{key}=", val) if respond_to?("#{key}=")
    end
    if source == :person
      @scope = Person.joins(:family)
    elsif source == :family
      @scope = Family.includes(:people)
    end

    @ilike = (@scope.connection.adapter_name == "PostgreSQL" ? 'ilike' : 'like')
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

  def birthday(key=nil)
    if key
      @birthday.try(:[], key).to_i
    else
      @birthday
    end
  end

  def anniversary(key=nil)
    if key
      @anniversary.try(:[], key).to_i
    else
      @anniversary
    end
  end

  def address(key=nil)
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
    order_by_name!
    parental_consent!
    visible!
    name!
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

  def order_by_name!
    order!('people.last_name, people.first_name')
  end

  def parental_consent!
    return if show_hidden_profiles?
    where!("(people.child = ? or coalesce(people.parental_consent, '') != '')", false)
  end

  def visible!
    return if show_hidden_profiles?
    where!(people: { visible: true, visible_to_everyone: true })
    where!(families: { visible: true })
  end

  def name!
    return unless name
    person = Person.arel_table
    family = Family.arel_table
    concat = Arel::Nodes::NamedFunction.new 'concat', [person[:first_name], ' ', person[:last_name]]

    where!(concat.matches(like(name)).or(
      family[:name].matches(like(name)).or(
        person[:first_name].matches(like(name.split.first, :after)).and(
          person[:last_name].matches(like(name.split.last, :after))))))
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
    where!("families.city #{@ilike} ?",  like(address[:city],  :after)) if address[:city].present?
    where!("families.state #{@ilike} ?", like(address[:state], :after)) if address[:state].present?
    where!("families.zip #{@ilike} ?",   like(address[:zip],   :after)) if address[:zip].present?
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
      where!("people.custom_type = ?", type)
    end
  end

  def family_barcode_id!
    where!('families.barcode_id = :id or families.alternate_barcode_id = :id', id: family_barcode_id) if family_barcode_id
  end

  def show_hidden_profiles?
    ((show_hidden || select_person || select_family) && Person.logged_in.admin?(:view_hidden_profiles))
  end

  def like(str, position=:both)
    str.to_s.dup.gsub(/[%_]/) { |x| '\\' + x }.tap do |s|
      s.insert(0, '%') if [:before, :both].include?(position)
      s << '%'         if [:after,  :both].include?(position)
    end
  end
end
