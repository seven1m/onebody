class Search
  
  ITEMS_PER_PAGE = 100
  
  attr_accessor :show_businesses, :show_hidden, :testimony, :member
  attr_reader :count, :people, :family_name, :families
  
  def initialize
    @people = []
    @family_name = nil
    @families = []
    @conditions = []
  end
  
  def name=(name)
    if name
      name.gsub! /\sand\s/, ' & '
      @conditions.add_condition ["(#{sql_concat('people.first_name', %q(' '), 'people.last_name')} like ? or (#{name.index('&') ? '1=1' : '1=0'} and families.name like ?) or (people.first_name like ? and people.last_name like ?))", "%#{name}%", "%#{name}%", "#{name.split.first}%", "#{name.split.last}%"]
    end
  end

  def family_name=(family_name)
    @family_name = family_name
    if family_name
      family_name.gsub! /\sand\s/, ' & '
      @conditions.add_condition ["(families.name like ? or families.last_name like ? or (select count(*) from people where family_id=families.id and #{sql_concat('people.first_name', %q(' '), 'people.last_name')} like ?) > 0)", "%#{family_name}%", "%#{family_name}%", "#{family_name}%"]
    end
  end
  
  def family_id=(id)
    @conditions.add_condition ["people.family_id = ?", id] if id
  end
  
  def family=(fam); family_id = fam.id if fam; end
  
  def business_category=(cat)
    @conditions.add_condition ["people.business_category = ?", cat] if cat
  end
  
  def gender=(g)
    @conditions.add_condition ["people.gender = ?", g] if g
  end
  
  def address=(addr)
    addr.symbolize_keys!.reject_blanks!
    @conditions.add_condition ["#{sql_lcase('families.city')} LIKE ?", "#{addr[:city].downcase}%"] if addr[:city]
    @conditions.add_condition ["#{sql_lcase('families.state')} LIKE ?", "#{addr[:state].downcase}%"] if addr[:state]
    @conditions.add_condition ["families.zip like ?", "#{addr[:zip]}%"] if addr[:zip]
    @search_address = addr.any?
  end
  
  def birthday=(bday)
    bday.symbolize_keys!.reject_blanks!
    @conditions.add_condition ["#{sql_month('people.birthday')} = ?", bday[:month]] if bday[:month]
    @conditions.add_condition ["#{sql_day('people.birthday')} = ?", bday[:day]] if bday[:day]
    @search_birthday = bday.any?
  end
  
  def anniversary=(ann)
    ann.symbolize_keys!.reject_blanks!
    @conditions.add_condition ["#{sql_month('people.anniversary')} = ?", ann[:month]] if ann[:month]
    @conditions.add_condition ["#{sql_day('people.anniversary')} = ?", ann[:day]] if ann[:day]
    @search_anniversary = ann.any?
  end
  
  def favorites=(favs)
    favs.reject! { |n, v| not %w(activities interests music tv_shows movies books).include? n.to_s or v.to_s.empty? }
    favs.each do |name, value|
      @conditions.add_condition ["people.#{name.to_s} like ?", "%#{value}%"]
    end
  end
  
  def type=(type)
    if type
      if %w(member staff deacon elder).include?(type.downcase)
        @type = type.downcase
      else
        @type = type if Person.custom_types.include?(type)
      end
    end
  end
  
  def query(page=nil, search_by=:person)
    case search_by.to_s
      when 'person'
        query_people(page)
      when 'family'
        query_families(page)
    end
  end
  
  def query_people(page=nil)
    @conditions.add_condition ["people.deleted = ?", false]
    @conditions.add_condition ["people.business_name is not null and people.business_name != ''"] if show_businesses
    @conditions.add_condition ["people.testimony is not null and people.testimony != ''"] if testimony
    unless show_hidden and Person.logged_in.admin?(:view_hidden_profiles)
      @conditions.add_condition ["people.visible_to_everyone = ?", true]
      @conditions.add_condition ["(people.visible = ? and families.visible = ?)", true, true]
      unless SQLITE
        @conditions.add_condition ["(people.child = ? or (birthday is not null and adddate(birthday, interval 13 year) <= curdate()) or (people.parental_consent is not null and people.parental_consent != ''))", false]
      end
    end
    unless Person.logged_in.full_access?
      if SQLITE
        @conditions.add_condition ["#{sql_now}-people.birthday >= 18"]
      else
        @conditions.add_condition ["DATE_ADD(people.birthday, INTERVAL 18 YEAR) <= CURDATE()"]
      end
    end
    if @type
      if %w(member staff deacon elder).include?(@type)
        @conditions.add_condition ["people.#{@type} = ?", true]
      else
        @conditions.add_condition ["people.custom_type = ?", @type]
      end
    end
    @count = Person.count :conditions => @conditions, :include => :family
    @people = Person.paginate(
      :all,
      :page => page,
      :conditions => @conditions,
      :include => :family,
      :order => (show_businesses ? 'people.business_name' : 'people.last_name, people.first_name')
    ).select do |person| # additional checks that don't work well in raw sql
      !person.nil? \
        and Person.logged_in.sees?(person) \
        and (not @search_birthday or person.share_birthday_with(Person.logged_in)) \
        and (not @search_anniversary or person.share_anniversary_with(Person.logged_in)) \
        and (not @search_address or person.share_address_with(Person.logged_in)) \
        and (person.consent_or_13? or (Person.logged_in.admin?(:view_hidden_profiles) and @show_hidden))
    end
    @people = WillPaginate::Collection.new(page || 1, 30, @count).replace(@people)
  end
  
  def query_families(page=nil)
    @conditions.add_condition ["families.deleted = ?", false]
    @count = Family.count :conditions => @conditions
    @families = Family.paginate(:all, :page => page, :conditions => @conditions, :order => "last_name")
  end
  
  def self.new_from_params(params)
    search = new
    search.name = params[:name] || params[:quick_name]
    search.family_name = params[:family_name]
    search.show_businesses = params[:business] || params[:businesses]
    search.business_category = params[:category]
    search.testimony = params[:testimony]
    search.family_id = params[:family_id]
    search.show_hidden = params[:show_hidden]
    search.birthday = {:month => params[:birthday_month], :day => params[:birthday_day]}
    search.anniversary = {:month => params[:anniversary_month], :day => params[:anniversary_day]}
    search.gender = params[:gender]
    search.address = params.reject { |k, v| not %w(city state zip).include? k }
    search.type = params[:type]
    search.favorites = params.reject { |k, v| not %w(activities interests music tv_shows movies books).include? k }
    search.show_hidden = true if params[:select_person] and Person.logged_in.admin?(:view_hidden_profiles)
    search
  end
end
