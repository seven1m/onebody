class Report < ActiveRecord::Base
  unloadable
  
  scope_by_site_id
  has_and_belongs_to_many :admins
  belongs_to :last_run_by, :class_name => 'Person'
  belongs_to :created_by, :class_name => 'Person'
  
  serialize :definition, Hash
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  VALID_COLLECTIONS = %w(people groups)
  
  validates_each :definition do |record, attribute, value|
    unless VALID_COLLECTIONS.include?(value['collection']) \
      and value['selector'].is_a?(Array)
      record.errors.add(attribute, :invalid)
    end
  end
  
  DEFAULT_DEFINITION = {'definition' => {'collection' => 'people', 'selector' => {}}}
  
  after_save :delete_associations_if_unrestricted
  
  def delete_associations_if_unrestricted
    admins.clear unless restricted?
  end
  
  def runnable_by?(person)
    person.super_admin? or !restricted? or \
      (person.admin and person.admin.reports.find(id))
  end
  
  def run
    if collection and definition['selector']
      f = collection.find(selector_to_javascript, definition['options'] || {})
      f.count # get Mongo to thrown an error if there's a problem
      increment(:run_count)
      self.last_run_at = Time.now
      self.last_run_by_id = Person.logged_in.id if Person.logged_in
      save
      return f
    else
      false
    end
  end
  
  def self.connect_mongo!
    config = YAML::load_file(RAILS_ROOT + '/config/database.yml')['mongo'] rescue nil
    if config
      begin
        MONGO_CONNECTIONS[Site.current.id] = Mongo::Connection.new(config['host']).db("#{config['database']}_for_site#{Site.current.id}")
      rescue Mongo::ConnectionFailure
        RAILS_DEFAULT_LOGGER.error('Could not connect to Mongodb server.')
        nil
      end
    else
      RAILS_DEFAULT_LOGGER.error('No configuration found in database.yml for Mongodb.')
      nil
    end
  end
  
  def self.db
    MONGO_CONNECTIONS[Site.current.id] || begin
      connect_mongo!
      MONGO_CONNECTIONS[Site.current.id]
    end
  end
  
  def collection
    if definition.is_a?(Hash) and definition['collection']
      @collection ||= self.class.db[definition['collection']]
    end
  end
  
  def selector_for_form
    definition['selector'].map { |c| condition_for_form(c) }.flatten
  end
  
  def condition_for_form(cond)
    if ['$or', '$and'].include?(cond.first)
      [
        {'field' => '(', 'operator' => cond.first},
        cond.last.map { |c| condition_for_form(c) },
        {'field' => ')', 'operator' => cond.first}
      ].flatten
    else
      field, operator, value = cond
      if value.is_a?(Regexp)
        value = value.source
      elsif value.is_a?(Array)
        value = value.join('|')
      end
      {'field' => field, 'operator' => operator, 'value' => value}
    end
  end
  
  def complex_condition_for_form(field, operator, value)
    if value.is_a?(Array)
      [field, operator, value.join('|')]
    elsif operator == '$ne' and value == nil
      [field, '$nnil']
    else
      [field, operator, value]
    end
  end
  
  def selector=(params)
    definition['selector'] = convert_selector_params(combine_selector_params(params))
  end
  
  def combine_selector_params(params)
    sel = []
    params[:field].each_with_index do |field, index|
      sel << [field, params[:operator][index], params[:value][index]]
    end
    return sel
  end
  
  def convert_selector_params(params)
    sel = {}
    params.each do |field, operator, value|
      if field =~ /^(and|or)(\d+)/
        
      else
        case operator
          when '=~'
            sel[field] = Regexp.new(value)
          when '=~i'
            sel[field] = Regexp.new(value, Regexp::IGNORECASE)
          when '='
            sel[field] = typecast_selector_value(field, operator, value)
          when '$nil'
            sel[field] = nil
          when '$nnil'
            sel[field] ||= {}
            sel[field]['$ne'] = nil
          else
            sel[field] ||= {}
            sel[field][operator] = typecast_selector_value(field, operator, value)
        end
      end
    end
    return sel
  end
  
  # Selector should be that which is consumable by the report html form.
  # * A simple conditional takes the form: [field, operator, value]
  #   * Fields are those avaialable from Report::PEOPLE_FIELDS
  #   * Operators are those listed in Report::OPERATORS_AND_TYPES
  #   * Values are of proper type, i.e. integer, boolean -- only strings should be in string form.
  # * A set of joined conditionals takes the form (using $and/$or): ['$and', ARRAY_OF_CONDITIONALS]
  # * definition['selector'] will always be an array of one element, e.g.
  #   * [['$and', ARRAY_OF_CONDITIONALS]]
  #   * [['$or',  ARRAY_OF_CONDITIONALS]]
  # * A complete sample:
  #   definition['selector'] = [
  #     ['$and', [
  #       ['gender', '=', 'Male'],
  #       ['child',  '=',  true ]
  #     ]
  #   ]
  
  def selector_to_javascript
    'return ' + conditional_to_javascript('this', definition['selector'].first) + ';'
  end
  
  JOINERS = {
    '$and' => ' && ',
    '$or'  => ' || '
  }
  
  # select function required to be in MongoDB
  # TODO: figure out how to auto-insert this into Mongo when first starting up
  # db.system.js.save({_id: "select", value: function(arr, fun){ var matched=[]; for(var i=0; i<arr.length; i++) { if(fun(arr[i])) matched.push(arr[i]) }; return matched; } });
  
  def conditional_to_javascript(context, cond)
    if joiner = JOINERS[cond.first]
      '(' + cond.last.map { |c| conditional_to_javascript(context, c) }.join(joiner) + ')'
    else
      field, operator, value = cond
      if field =~ /^(#{ONE_TO_MANY_ASSOCIATIONS.join('|')})\.(.+)/
        c = conditional_to_javascript('i', [$2, operator, value])
        "select(this.#{$1}, function(i){ return #{c} }).length > 0"
      else
        if op = {
          '$in'  => '>',
          '$nin' => '=='}[operator]
          "#{value.inspect}.indexOf(#{context}.#{field}) #{op} -1"
        elsif op = {
          '$lt'  => '<',
          '$lte' => '<=',
          '$gt'  => '>',
          '$gte' => '>=',
          '$ne'  => '!='}[operator]
          "#{context}.#{field} #{op} #{value.inspect}"
        elsif op = {
          '$nil'  => '==',
          '$nnil' => '!='}[operator]
          "#{context}.#{field} #{op} null"
        elsif ['=~', '=~i'].include?(operator)
          "(#{context}.#{field} && #{context}.#{field}.match(#{value.inspect}))"
        else
          "#{context}.#{field} == #{value.nil? ? 'null' : value.inspect}"
        end
      end
    end
  end
  
  def typecast_selector_value(field, operator, value)
    if %w($nil $nnil).include?(operator)
      nil
    elsif %w($in $nin).include?(operator)
      value.split('|').map { |v| typecast_selector_value(field, '=', v) }
    elsif definition['collection'] == 'people' and field_def = PEOPLE_FIELDS.detect { |f| f[0] == field }
      case field_def[1]
        when 'integer' then value.to_i
        when 'boolean' then value == 'true'
        else value
      end
    else
      value
    end
  end
  
  PEOPLE_FIELDS = (
    Person.columns.map     { |c| [c.name,                        c.type.to_s] }.sort +
    Admin.columns.map      { |c| ["admin.#{c.name}",             c.type.to_s] }.sort +
    Group.columns.map      { |c| ["groups.#{c.name}",            c.type.to_s] }.sort +
    Membership.columns.map { |c| ["groups.membership.#{c.name}", c.type.to_s] }.sort
  ).reject { |col, type| col =~ /site_id$/ }
  
  ONE_TO_MANY_ASSOCIATIONS = ['groups']
  
  def self.field_type(field)
    PEOPLE_FIELDS.detect { |f, t| f == field }[1] rescue nil
  end
  
  OPERATORS_AND_TYPES = [
    [I18n.t('reporting.is_exactly'),               '='                                                       ],
    [I18n.t('reporting.matches_case_sensitive'),   '=~',    ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.matches_case_insensitive'), '=~i',   ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.less_than'),                '$lt',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.less_than_or_equal'),       '$lte',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.greater_than'),             '$gt',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.greater_than_or_equal'),    '$gte',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.is_not'),                   '$ne',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.one_of'),                   '$in',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.not_one_of'),               '$nin',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.is_nil'),                   '$nil'                                                    ],
    [I18n.t('reporting.is_not_nil'),               '$nnil'                                                   ]
  ]
  
  def self.operators_for_field(collection, field)
    ops = OPERATORS_AND_TYPES.dup
    unless field == ''
      type = PEOPLE_FIELDS.detect { |f, t| f == field }[1]
      ops.reject! { |o| o[2] and !o[2].include?(type) }
    end
    ops.map { |o| o[0..1] }
  end
  
end
