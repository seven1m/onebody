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
  
  BLANK_CONDITION = ['', '=', '']
  
  DEFAULT_DEFINITION = {'definition' => {'collection' => 'people', 'selector' => [['$and', [BLANK_CONDITION]]]}}
  
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
  
  # Nested Selector Definition
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
  #
  # Flattened Selector Definition
  # * A simple conditional takes the form: {'field' => field, 'operator' => operator, 'value' => value}
  #   * Some values are converted to string representations:
  #     * A Regexp is converted to a string of its source representation
  #     * An Array is converted to a string, with its members joined with by a pipe (|)
  # * A set of joined conditionals is preceded with:
  #   * {'field' => '(', 'operator' => '$and'}
  #   ... and followed by:
  #   * {'field' => ')', 'operator' => '$and'}
  # * A complete sample:
  #   [
  #     {'field' => '(',      'operator' => '$and'                  },
  #     {'field' => 'gender', 'operator' => '=',   'value' => 'Male'},
  #     {'field' => 'child',  'operator' => '=',   'value' => true  },
  #     {'field' => ')',      'operator' => '$and'                  }
  #   ]
  
  
  # Selector Definition Conversion - TO
  
  def selector_for_form
    definition['selector'].map { |c| Report.condition_for_form(c) }.flatten
  end
  
  def self.condition_for_form(cond)
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
  
  def self.add_condition_to_params!(params, index)
    params.insert(index+1, condition_for_form(BLANK_CONDITION))
  end
  
  def self.remove_condition_from_params!(params, index)
    params.delete_at(index)
    remove_empty_groups_from_params!(params)
    if params.empty?
      condition_for_form(['$and', [BLANK_CONDITION]]).reverse.each do |part|
        params.insert(0, part)
      end
    end
  end
  
  def self.remove_empty_groups_from_params!(params)
    begin
      complete = true
      params.each_with_index do |param, index|
        if index > 0 and ['(', ')'] == [params[index-1]['field'], params[index]['field']]
          params.delete_at(index-1)
          params.delete_at(index-1)
          complete = false # now that we've collapsed this one, there could be more...
        end
      end
    end while !complete
  end
  
  def self.add_group_to_params!(params, index)
    stack = []
    params.each_with_index do |param, i|
      break if i == index
      if param['field'] == '('
        stack.push(param['operator'])
      elsif param['field'] == ')'
        stack.pop
      end
    end
    conjunction = stack.any? && stack.last == '$and' ? '$or' : '$and'
    condition_for_form([conjunction, [BLANK_CONDITION, BLANK_CONDITION]]).each_with_index do |part, i|
      params.insert(index+i+1, part)
    end
  end
  
  def self.move_condition_in_params!(params, index, direction)
    # cannot go above or below top level parens ( and )
    return if index == 1 and direction == 'up'
    return if index == params.length-2 and direction == 'down'
    param = params.delete_at(index)
    if direction == 'up'
      params.insert(index-1, param)
    else
      params.insert(index+1, param)
    end
    remove_empty_groups_from_params!(params)
  end
  
  def self.flip_conjunctions_in_params!(params)
    params.each do |param|
      if ['(', ')'].include?(param['field'])
        param['operator'] = param['operator'] == '$and' ? '$or' : '$and'
      end
    end
  end
  
  # Selector Definition Conversion - FROM
  
  def selector=(params)
    definition['selector'] = convert_selector_params(params)
  end
  
  def convert_selector_params(params)
    sel = []
    stack = [sel]
    params.each do |param|
      if param['field'] == '('
        joined = [param['operator'], []]
        stack.last << joined
        stack.push(joined[1])
      elsif param['field'] == ')'
        stack.pop
      else
        case param['operator']
          when '=~'
            value = Regexp.new(param['value'])
          when '=~i'
            value = Regexp.new(param['value'], Regexp::IGNORECASE)
          when 'nil', '!nil'
            value = nil
          else
            value = typecast_selector_value(param['field'], param['operator'], param['value'])
        end
        stack.last << [param['field'], param['operator'], value]
      end
    end
    sel
  end
  
  # Selector Definition Conversion - JAVASCRIPT
  
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
        if %w(< <= > >= !=).include?(operator)
          "#{context}.#{field} #{operator} #{value.inspect}"
        elsif %w(=~ =~i).include?(operator)
          "(#{context}.#{field} && #{context}.#{field}.match(#{value.inspect}))"
        elsif %w(c ci).include?(operator)
          "(#{context}.#{field} && #{context}.#{field}#{operator == 'ci' ? '.toLowerCase()' : ''}.indexOf(#{value.inspect}#{operator == 'ci' ? '.toLowerCase()' : ''}) > -1)"
        elsif op = {'in' => '>', '!in' => '=='}[operator]
          "#{value.inspect}.indexOf(#{context}.#{field}) #{op} -1"
        elsif op = {'nil' => '==', '!nil' => '!='}[operator]
          "#{context}.#{field} #{op} null"
        else
          "#{context}.#{field} == #{value.nil? ? 'null' : value.inspect}"
        end
      end
    end
  end
  
  def typecast_selector_value(field, operator, value)
    if %w(nil !nil).include?(operator)
      nil
    elsif %w(in !in).include?(operator)
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
    [I18n.t('reporting.is_exactly'),                '='                                                     ],
    [I18n.t('reporting.contains_case_sensitive'),   'c',   ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.contains_case_insensitive'), 'ci',  ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.matches_case_sensitive'),    '=~',  ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.matches_case_insensitive'),  '=~i', ['string', 'text', 'time', 'datetime']           ],
    [I18n.t('reporting.less_than'),                 '<',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.less_than_or_equal'),        '<=',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.greater_than'),              '>',   ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.greater_than_or_equal'),     '>=',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.is_not'),                    '!=',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.one_of'),                    'in',  ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.not_one_of'),                '!in', ['string', 'text', 'integer', 'time', 'datetime']],
    [I18n.t('reporting.is_nil'),                    'nil'                                                   ],
    [I18n.t('reporting.is_not_nil'),                '!nil'                                                  ]
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
