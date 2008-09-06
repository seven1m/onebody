class Search
  
  ITEMS_PER_PAGE = 100
  
  attr_accessor :show_services, :show_hidden, :testimony, :member
  attr_reader :count, :people
  
  def initialize
    @people = []
    @conditions = []
  end
  
  def name=(name)
    if name
      name.gsub! /\sand\s/, ' & '
      @conditions.add_condition ["(#{sql_concat('people.first_name', %q(' '), 'people.last_name')} like ? or (#{name.index('&') ? '1=1' : '1=0'} and families.name like ?) or (people.first_name like ? and people.last_name like ?))", "%#{name}%", "%#{name}%", "#{name.split.first}%", "#{name.split.last}%"]
    end
  end
  
  def family_id=(id)
    @conditions.add_condition ["people.family_id = ?", id] if id
  end
  
  def family=(fam); family_id = fam.id if fam; end
  
  def service_category=(cat)
    @conditions.add_condition ["people.service_category = ?", cat] if cat
  end
  
  def address=(addr)
    addr.symbolize_keys!.reject_blanks!
    @conditions.add_condition ["#{sql_lcase('families.city')} = ?", addr[:city].downcase] if addr[:city]
    @conditions.add_condition ["#{sql_lcase('families.state')} = ?", addr[:state].downcase] if addr[:state]
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
    @type = type.downcase if type and %w(member staff deacon elder).include? type.downcase
  end
  
  def query(page=nil)
    @conditions.add_condition ["people.service_name is not null and people.service_name != ''"] if show_services
    @conditions.add_condition ["people.testimony is not null and people.testimony != ''"] if testimony
    unless show_hidden and Person.logged_in.admin?(:view_hidden_profiles)
      @conditions.add_condition ["people.visible_to_everyone = ?", true]
      @conditions.add_condition ["(people.visible = ? and families.visible = ?)", true, true]
    end
    unless Person.logged_in.full_access?
      if SQLITE
        @conditions.add_condition ["#{sql_now}-people.birthday >= 18"]
      else
        @conditions.add_condition ["DATE_ADD(people.birthday, INTERVAL 18 YEAR) <= CURDATE()"]
      end
    end
    @conditions.add_condition ["people.#{@type} = ?", true] if @type
    @count = Person.count :conditions => @conditions, :include => :family
    @people = Person.paginate(
      :all,
      :page => page,
      :conditions => @conditions,
      :include => :family,
      :order => (show_services ? 'people.service_name' : 'people.last_name, people.first_name')
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
  
  def self.new_from_params(params)
    search = new
    search.name = params[:name] || params[:quick_name]
    search.show_services = params[:service] || params[:services]
    search.service_category= params[:category]
    search.testimony = params[:testimony]
    search.family_id = params[:family_id]
    search.show_hidden = params[:show_hidden]
    search.birthday = {:month => params[:birthday_month], :day => params[:birthday_day]}
    search.anniversary = {:month => params[:anniversary_month], :day => params[:anniversary_day]}
    search.address = params.reject { |k, v| not %w(city state zip).include? k }
    search.type = params[:type]
    search.favorites = params.reject { |k, v| not %w(activities interests music tv_shows movies books).include? k }
    search
  end
end
