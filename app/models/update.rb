class Update < ActiveRecord::Base
  PERSON_ATTRIBUTES = %w(first_name last_name mobile_phone work_phone fax birthday anniversary suffix gender custom_fields)
  FAMILY_ATTRIBUTES = %w(family_name family_last_name home_phone address1 address2 city state zip)

  belongs_to :person
  belongs_to :site

  scope_by_site_id

  serialize :custom_fields

  attr_accessor :child

  self.skip_time_zone_conversion_for_attributes = [:birthday, :anniversary]

  def custom_fields
    (f = read_attribute(:custom_fields)).is_a?(Array) ? f : []
  end

  def custom_fields_as_hash
    {}.tap do |hash|
      Setting.get(:features, :custom_person_fields).each_with_index do |field, index|
        hash[index] = custom_fields[index] if custom_fields[index]
      end
    end
  end

  def custom_fields=(values)
    existing_values = read_attribute(:custom_fields) || []
    if values.is_a?(Hash)
      values.each do |key, val|
        existing_values[key.to_i] = typecast_custom_value(val, key.to_i)
      end
    else
      values.each_with_index do |val, index|
        existing_values[index] = typecast_custom_value(val, index)
      end
    end
    write_attribute(:custom_fields, existing_values)
  end

  def typecast_custom_value(val, index)
    if Setting.get(:features, :custom_person_fields)[index] =~ /[Dd]ate/
      Date.parse(val.to_s) rescue nil
    else
      val
    end
  end

  def do!
    raise 'Unauthorized' unless Person.logged_in.admin?(:manage_updates)
    success = person.update_attributes(person_attributes) && person.family.update_attributes(family_attributes)
    unless success
      person.errors.full_messages.each        { |m| self.errors.add :base, m }
      person.family.errors.full_messages.each { |m| self.errors.add :base, m }
    end
    return success
  end

  self.digits_only_for_attributes = [:mobile_phone, :work_phone, :fax, :home_phone]

  def person_attributes
    attrs = self.attributes.reject { |key, val| !PERSON_ATTRIBUTES.include?(key) }
    attrs['custom_fields'] = custom_fields_as_hash
    attrs['child'] = child
    attrs
  end

  def person_attributes=(attributes)
    self.attributes = attributes
  end

  def family_attributes
    {
      :name      => self.family_name,
      :last_name => self.family_last_name,
    }.merge(self.attributes.reject { |k, v| !(FAMILY_ATTRIBUTES - %w(family_name family_last_name)).include?(k) })
  end

  def family_attributes=(attributes)
    attributes = attributes.clone
    self.family_name = attributes.delete(:name)
    self.family_last_name = attributes.delete(:last_name)
    self.attributes = attributes
  end

  def changes
    p = self.person
    p.attributes = person_attributes
    p_changes = p.changes.clone
    p_changes.delete('custom_fields') if p_changes['custom_fields'] and p_changes['custom_fields'] == [nil, []]
    f = p.family
    f.attributes = family_attributes
    f_changes = f.changes.clone
    f_changes['family_name']      = f_changes.delete('name')      if f_changes['name']
    f_changes['family_last_name'] = f_changes.delete('last_name') if f_changes['last_name']
    p_changes.merge(f_changes)
  end

  def self.create_from_params(params, person)
    params = HashWithIndifferentAccess.new(params) unless params.is_a? HashWithIndifferentAccess
    person.updates.new.tap do |update|
      update.person_attributes = params[:person].reject { |k, v| !PERSON_ATTRIBUTES.include?(k) }.reject_blanks if params[:person]
      Rails.logger.info(params[:family].inspect)
      update.family_attributes = params[:family].reject { |k, v| !(FAMILY_ATTRIBUTES+%w(name last_name)).include?(k) }.reject_blanks if params[:family]
      update.save
      Notifier.profile_update(person, update.changes).deliver if Setting.get(:contact, :send_updates_to)
    end
  end

  def self.daily_counts(limit, offset, date_strftime='%Y-%m-%d', only_show_date_for=nil)
    [].tap do |data|
      counts = connection.select_all("select count(date(created_at)) as count, date(created_at) as date from updates where site_id=#{Site.current.id} group by date(created_at) order by created_at desc limit #{limit} offset #{offset};").group_by { |p| Date.parse(p['date']) }
      ((Date.today-offset-limit+1)..(Date.today-offset)).each do |date|
        d = date.strftime(date_strftime)
        d = ' ' if only_show_date_for and date.strftime(only_show_date_for[0]) != only_show_date_for[1]
        count = counts[date] ? counts[date][0]['count'].to_i : 0
        data << [d, count]
      end
    end
  end

end
