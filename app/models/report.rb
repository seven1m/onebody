class Report < ActiveRecord::Base
  unloadable
  
  scope_by_site_id
  has_and_belongs_to_many :admins
  belongs_to :last_run_by, :class_name => 'Person'
  belongs_to :created_by, :class_name => 'Person'
  
  serialize :definition, Hash
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  MONGO_DB = "onebody_#{RAILS_ENV}"
  
  VALID_COLLECTIONS = %w(people groups)
  
  validates_each :definition do |record, attribute, value|
    unless VALID_COLLECTIONS.include?(value['collection']) \
      and value['selector'].is_a?(Hash)
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
      f = collection.find(definition['selector'], definition['options'] || {})
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
  
  def db
    @db ||= Mongo::Connection.new.db("#{MONGO_DB}_for_site#{Site.current.id}")
  end
  
  def collection
    if definition.is_a?(Hash) and definition['collection']
      @collection ||= db[definition['collection']]
    end
  end
  
  def selector_for_form
    definition['selector'].sort.inject([]) do |array, item|
      field, value = item
      if value.is_a?(Hash)
        array += value.sort.map do |v|
          if v[1].is_a?(Array)
            [field, v[0], v[1].join('|')]
          elsif v[0] == '$ne' and v[1] == nil
            [field, '$nnil']
          else
            [field, v[0], v[1]]
          end
        end
      else
        if value.is_a?(Regexp)
          if value.options & Regexp::IGNORECASE > 0
            array << [field, '=~i', value.source]
          else
            array << [field, '=~', value.source]
          end
        elsif value == nil
          array << [field, '$nil']
        else
          array << [field, '=', value]
        end
      end
      array
    end
  end
  
  def selector=(params)
    sel = {}
    params[:field].each_with_index do |field, index|
      case operator = params[:operator][index]
        when '=~'
          sel[field] = Regexp.new(params[:value][index])
        when '=~i'
          sel[field] = Regexp.new(params[:value][index], Regexp::IGNORECASE)
        when '='
          sel[field] = typecast_selector_value(field, operator, params[:value][index])
        when '$nil'
          sel[field] = nil
        when '$nnil'
          sel[field] ||= {}
          sel[field]['$ne'] = nil
        else
          sel[field] ||= {}
          sel[field][operator] = typecast_selector_value(field, operator, params[:value][index])
      end
    end
    definition['selector'] = sel
  end
  
  def convert_selector
    return unless definition['selector'].is_a?(Hash)
    'return ' +
    definition['selector'].sort.map do |field, value|
      if field =~ /^groups\.(.+)/
        cond = build_conditional('i', $1, value)
        "select(this.groups, function(i){ return #{cond} }).length > 0"
      else
        build_conditional('this', field, value)
      end
    end.join(' && ') + ';'
  end
  
  def build_conditional(context, field, value)
    if value.is_a?(Hash)
        value.sort.map do |op, v|
          if v.is_a?(Array)
            op = {
              '$in'  => '>',
              '$nin' => '=='
            }[op]
            "#{v.inspect}.indexOf(#{context}.#{field}) #{op} -1"
          else
            op = {
              '$lt'  => '<',
              '$lte' => '<=',
              '$gt'  => '>',
              '$gte' => '>=',
              '$ne'  => '!='
            }[op]
            "#{context}.#{field} #{op} #{v.nil? ? 'null' : v.inspect}"
          end
        end.join(' && ')
      elsif value.is_a?(Regexp)
        "#{context}.#{field}.match(#{value.inspect})"
      else
        "#{context}.#{field} == #{value.nil? ? 'null' : value.inspect}"
      end
  end
  
  def convert_selector!
    self.definition['selector'] = convert_selector
  end
  
  def typecast_selector_value(field, operator, value)
    if %w($nil $nnil).include?(operator)
      nil
    elsif %w($in $nin).include?(operator)
      value.split('|').map { |v| typecast_selector_value(field, '=', v) }
    elsif definition['collection'] == 'people' and field_def = self.class.people_fields.detect { |f| f[0] == field }
      case field_def[1]
        when 'integer' then value.to_i
        when 'boolean' then value == 'true'
        else value
      end
    else
      value
    end
  end
  
  def self.people_fields
    (
      Person.columns.map     { |c| [c.name,                        c.type.to_s] }.sort +
      Admin.columns.map      { |c| ["admin.#{c.name}",             c.type.to_s] }.sort +
      Group.columns.map      { |c| ["groups.#{c.name}",            c.type.to_s] }.sort +
      Membership.columns.map { |c| ["groups.membership.#{c.name}", c.type.to_s] }.sort
    ).reject { |col, type| col =~ /site_id$/ }
  end
  
  def self.field_type(field)
    people_fields.detect { |f, t| f == field }[1] rescue nil
  end
  
  def self.operators_and_types
    [
      [I18n.t('reporting.is_exactly'),               '='                                                      ],
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
  end
  
  def self.operators_for_field(collection, field)
    ops = operators_and_types.dup
    unless field == ''
      type = people_fields.detect { |f, t| f == field }[1]
      ops.reject! { |o| o[2] and !o[2].include?(type) }
    end
    ops.map { |o| o[0..1] }
  end
  
end
