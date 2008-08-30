#!/usr/bin/env ruby

# OneBody Update Agent

# To use, copy this script (updateagent.rb) somewhere.
# The script can run locally or remotely, separately from OneBody.

# Using your membership management software, reporting solution,
# database utility, custom script, etc., export your people
# and family data to a single comma separated values (CSV) file,
# e.g. people.csv.

# Duplicate family data should be present for each member of
# the same family.

# The first row of the file is the attribute headings, and must
# exactly match the attributes available, e.g. see app/models/person.rb
# and app/models/family.rb (prefixed with "family_"). Not all
# attributes are required (use as few as needed).

# Or, you can run "rake onebody:export:people:csv" to export current
# OneBody data (if you have any records in the OneBody database) as
# a starting point.

# Use the attributes "legacy_id" and "legacy_family_id" in order to
# track the identity/foreign keys from your existing membership
# management database. You should *not* use/include "id" and
# "family_id" unless you know what you're doing.

# Edit the first three constants below to match your environment. You
# can get your api key from OneBody (you must be a super user) by
# running the following command (on the server):
#   cd /path/to/onebody
#   rake onebody:api:key EMAIL=admin@example.com
# (use your own email address; account must already exist)

# Your SITE address will probably be something like http://example.com
# (not including ":3000", unless you are running in development mode).

# Run "ruby updateagent.rb" for command line usage and options.

SITE       = 'http://localhost:3000'
USER_EMAIL = 'admin@example.com'
USER_KEY   = 'dafH2KIiAcnLEr5JxjmX2oveuczq0R6u7Ijd329DtjatgdYcKp'

require 'date'
require 'csv'
require 'optparse'
require 'rubygems'
require 'highline/import'
require 'activeresource'
require 'digest/sha1'

HighLine.track_eof = false

class Base < ActiveResource::Base
  self.site     = SITE
  self.user     = USER_EMAIL
  self.password = USER_KEY
end

class Person < Base; end
class Family < Base; end

class Schema
  def initialize(resource)
    @schema = resource.get(:schema)
  end
  def type(t)
    @schema.select { |c| c['type'] == t }.map { |c| c['name'] }.uniq
  end
end
person_schema = Schema.new(Person)
family_schema = Schema.new(Family)

DATETIME_ATTRIBUTES = person_schema.type(:datetime) + family_schema.type(:datetime).map { |c| 'family_' + c }
BOOLEAN_ATTRIBUTES  = person_schema.type(:boolean)  + family_schema.type(:boolean).map  { |c| 'family_' + c }
IGNORE_ATTRIBUTES   = %w(updated_at created_at family_updated_at family_latitude family_longitude)

class Hash
  # creates a uniq sha1 digest of the hash's values
  # should mirror similar code in OneBody's lib/db_tools.rb
  def values_hash(*attrs)
    attrs = keys.sort unless attrs.any?
    attrs = attrs.first if attrs.first.is_a?(Array)
    values = attrs.map do |attr|
      value = self[attr.to_s]
      value.respond_to?(:strftime) ? value.strftime('%Y/%m/%d %H:%M') : value
    end
    Digest::SHA1.hexdigest(values.join)
  end
end

# general class to handle comparing and pushing data to the remote end
class UpdateAgent
  def initialize(data=nil)
    @attributes = []
    @data = []
    @create = []
    @update = []
    if data
      if data.is_a?(Array)
        @data = data
        @attributes = data.first.keys.sort
      else
        read_from_file(data)
      end
    end
    if invalid = @data.detect { |row| row['id'].to_s.any? and row['legacy_id'].to_s.any? }
      puts "Error: one or more records contain both 'id' and 'legacy_id' columns."
      puts "Please remove one of the columns or blank the values."
      puts "It is usually best to utilize 'legacy_id' rather than 'id' so that"
      puts "identity and foreign keys are maintained from your existing membership"
      puts "management database."
      exit
    end
  end
  
  # load data from csv file and do some type conversion for bools and dates
  # first row must be attribute names
  def read_from_file(filename)
    csv = CSV.open(filename, 'r')
    @attributes = csv.shift
    @data = csv.map do |row|
      hash = {}
      row.each_with_index do |value, index|
        key = @attributes[index]
        next if IGNORE_ATTRIBUTES.include?(key)
        if DATETIME_ATTRIBUTES.include?(key)
          if value.blank?
            value = nil
          else
            begin
              value = DateTime.parse(value)
            rescue ArgumentError
              puts "Invalid date in #{filename} record #{index} (#{key}) - #{value}"
              exit(1)
            end
          end
        elsif BOOLEAN_ATTRIBUTES.include?(key)
          if value == '' or value == nil
            value = nil
          elsif %w(no false 0).include?(value.downcase)
            value = false
          else
            value = true
          end
        end
        hash[key] = value
      end
      hash
    end
    @attributes.reject! { |a| IGNORE_ATTRIBUTES.include?(a) }
  end
  
  def ids
    @data.map { |r| r['id'] }.compact
  end
  
  def legacy_ids
    @data.map { |r| r['legacy_id'] }.compact
  end

  def compare
    compare_hashes(ids)
    compare_hashes(legacy_ids, true)
  end
  
  def has_work?
    (@create + @update).any?
  end

  def present
    puts "The following #{resource.name.downcase} records will be pushed..."
    puts 'legacy id  name'
    puts '---------- -------------------------------------'
    @create.each { |r| present_record(r, true) }
    @update.each { |r| present_record(r) }
    puts
  end
  
  def present_record(row, new=false)
    puts "#{row['legacy_id'].to_s.ljust(10)} #{name_for(row)} #{new ? '(new)' : ''}"
  end
  
  def confirm
    agree('Do you want to continue, pushing these records to OneBody? ')
  end
  
  # use ActiveResource to create/update records on remote end
  def push
    puts 'Updating remote end...'
    @create.each do |row|
      puts "Pushing #{resource.name.downcase} #{name_for(row)} (new)"
      record = resource.new
      record.attributes.merge! row.reject { |k, v| k == 'id' }
      record.save
      row['id'] = record.id
    end
    @update.each do |row|
      puts "Pushing #{resource.name.downcase} #{name_for(row)}"
      record = row['id'] ? resource.find(row['id']) : resource.find(row['legacy_id'], :params => {:legacy_id => true})
      record.attributes.merge! row.reject { |k, v| k == 'id' }
      record.save
      row['id'] = record.id
    end
  end

  attr_accessor :attributes, :data
  attr_reader :update, :create
  
  class << self; attr_accessor :resource; end
  def resource; self.class.resource; end
  
  protected
  
  # ask remote end for value hashe for each record (50 at a time) 
  # mark records to create or update based on response
  def compare_hashes(ids, legacy=false)
    ids.each_slice(50) do |some_ids|
      resource.get(:hashify, :attrs => @attributes, legacy ? :legacy_ids : :ids => ids).each do |record|
        row = @data.detect { |r| legacy ? (r['legacy_id'] == record['legacy_id']) : (r['id'] == record['id']) }
        if record['exists']
          @update << row if row.values_hash(@attributes) != record['hash']
        else
          @create << row
        end
      end
    end
  end
end

# handles people.csv and splits out family data for FamilyUpdater
class PeopleUpdater < UpdateAgent
  self.resource = Person
  
  # split out family data and create a new FamilyUpdater
  def initialize(filename)
    super(filename)
    person_data = []
    family_data = []
    @data.each do |row|
      person, family = split_change_hash(row)
      if existing_family = family_data.detect { |r| r.values_hash == family.values_hash }
        person['family'] = existing_family
        person_data << person
      else
        person['family'] = family
        person_data << person
        family_data << family
      end
    end
    @data = person_data
    @attributes.reject! { |a| a =~ /^family_/ and a != 'family_id' }
    @family_agent = FamilyUpdater.new(family_data)
  end
  
  def name_for(row)
    "#{row['first_name']} #{row['last_name']}"
  end
  
  def compare
    @family_agent.compare
    super
  end
  
  def has_work?
    @family_agent.has_work? or super
  end
  
  def present
    @family_agent.present if @family_agent.has_work?
    super
  end
  
  def push
    @family_agent.push
    @data.each do |row|
      # if the family was created, make sure the person record gets the new id
      row['family_id'] = row['family']['id'] if row['family']['id']
      row.delete('family')
    end
    super
  end
  
  protected
  
    # split hash of values into person and family values based on keys
    def split_change_hash(vals)
      person_vals = {}
      family_vals = {}
      vals.each do |key, val|
        if key =~ /^family_/
          family_vals[key.sub(/^family_/, '')] = val
        else
          person_vals[key] = val
        end
      end
      family_vals['legacy_id'] ||= person_vals['legacy_family_id']
      [person_vals, family_vals]
    end
end

class FamilyUpdater < UpdateAgent
  self.resource = Family
  def name_for(row)
    row['name']
  end
end

if __FILE__ == $0

  options = {:confirm => true}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby updateagent.rb [options] path/to/people.csv"
    opts.on("-y", "--no-confirm", "Assume 'yes' to any questions") do |v|
      options[:confirm] = false
    end
    opts.on("-l", "--log LOGFILE", "Output to log rather than stdout") do |log|
      $stdout = $stderr = File.open(log, 'a')
    end
  end
  opt_parser.parse!
  
  if ARGV[0] # path/to/people.csv
    puts "Update Agent running at #{Time.now.strftime('%m/%d/%Y %I:%M %p')}\n\n"
    agent = PeopleUpdater.new(ARGV[0])
    agent.compare
    if agent.has_work?
      if options[:confirm]
        agent.present
        unless agent.confirm
          puts "Canceled by user\n"
          exit
        end
      end
      agent.push
      puts "Completed at #{Time.now.strftime('%m/%d/%Y %I:%M %p')}\n\n"
    else
      puts "Nothing to push\n\n"
    end
  else
    puts opt_parser.help
  end
  
end
