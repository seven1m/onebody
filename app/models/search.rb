require 'ostruct'

class Search

  attr_accessor :name, :family_name,
                :gender,
                :address,
                :birthday, :anniversary,
                :type,
                :family_barcode_id,
                :business,
                :show_hidden

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

  private

  def execute!
    return if @executed
    not_deleted!
    business!
    order_by_name!
    parental_consent!
    name!
    gender!
    birthday!
    anniversary!
    address!
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
    where!('people.deleted = ? and families.deleted = ?', false, false)
  end

  def business!
    return unless business
    where!("coalesce(people.business_name) != ''")
    order!('people.business_name')
  end

  def order_by_name!
    order!('people.last_name, people.first_name')
  end

  def parental_consent!
    return unless require_parental_consent?
    where!(
      "(people.child = ?
       or (birthday is not null and adddate(birthday, interval 13 year) <= curdate())
       or (people.parental_consent is not null and people.parental_consent != ''))
      ",
      false
    )
  end

  def name!
    return unless name
    where!(
      "(concat(people.first_name, ' ', people.last_name) like :full_name
       or (families.name like :full_name)
       or (people.first_name like :first_name and people.last_name like :last_name))
      ",
      full_name:  like(name),
      first_name: like(name.split.first, :after),
      last_name:  like(name.split.last, :after)
    )
  end

  def gender!
    where!('people.gender = ?', gender) if gender.present?
  end

  def birthday!
    self.birthday ||= {}
    where!('month(people.birthday) = ?', birthday[:month]) if birthday[:month].present?
    where!('day(people.birthday)   = ?', birthday[:day])   if birthday[:day].present?
  end

  def anniversary!
    self.anniversary ||= {}
    where!('month(people.anniversary) = ?', anniversary[:month]) if anniversary[:month].present?
    where!('day(people.anniversary)   = ?', anniversary[:day])   if anniversary[:day].present?
  end

  def address!
    self.address ||= {}
    where!('families.city like ?',  like(address[:city],  :after)) if address[:city].present?
    where!('families.state like ?', like(address[:state], :after)) if address[:state].present?
    where!('families.zip like ?',   like(address[:zip],   :after)) if address[:zip].present?
  end

  def type!
    if %w(member staff deacon elder).include?(type)
      where!("people.#{type} = ?", true)
    elsif type.present?
      where!("people.custom_type = ?", type)
    end
  end

  def family_barcode_id!
    where!('families.barcode_id = ?', family_barcode_id) if family_barcode_id
  end

  def require_parental_consent?
    !(show_hidden && Person.logged_in.admin?(:view_hidden_profiles))
  end

  def like(str, position=:both)
    str.to_s.dup.gsub(/[%_]/) { |x| '\\' + x }.tap do |s|
      s.insert(0, '%') if [:before, :both].include?(position)
      s << '%'         if [:after,  :both].include?(position)
    end
  end
end
