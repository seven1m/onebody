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
require 'optparse'
require 'rubygems'
require 'fastercsv'
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
INTEGER_ATTRIBUTES  = person_schema.type(:integer)  + family_schema.type(:integer).map  { |c| 'family_' + c }
IGNORE_ATTRIBUTES   = %w(updated_at created_at family_updated_at family_latitude family_longitude)

MAX_HASHES_AT_A_TIME = 1000
MAX_TO_BATCH_AT_A_TIME = 25

DEBUG = false

class Hash
  # creates a uniq sha1 digest of the hash's values
  # should mirror similar code in OneBody's lib/db_tools.rb
  def values_hash(*attrs)
    attrs = keys.sort unless attrs.any?
    attrs = attrs.first if attrs.first.is_a?(Array)
    values = attrs.map do |attr|
      value = self[attr.to_s]
      if value.respond_to?(:strftime)
        value.strftime('%Y-%m-%d %H:%M:%S')
      elsif value == true
        1
      elsif value == false
        0
      else
        value
      end
    end
    DEBUG ? values.join : Digest::SHA1.hexdigest(values.join)
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
    if invalid = @data.detect { |row| row['id'] }
      puts "Error: one or more records contain an 'id' column."
      puts "You must utilize 'legacy_id' rather than 'id' so that"
      puts "identity and foreign keys are maintained from your"
      puts "existing membership management database."
      exit
    end
  end
  
  # load data from csv file and do some type conversion for bools and dates
  # first row must be attribute names
  def read_from_file(filename)
    csv = FasterCSV.open(filename, 'r')
    @attributes = csv.shift
    record_count = 0
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
        elsif INTEGER_ATTRIBUTES.include?(key)
          value = value.to_s != '' ? value.scan(/\d/).join.to_i : nil
        end
        hash[key] = value
      end
      record_count += 1
      print "reading record #{record_count}\r"
      hash
    end
    puts
    @attributes.reject! { |a| IGNORE_ATTRIBUTES.include?(a) }
  end
  
  def ids
    @data.map { |r| r['id'] }.compact
  end
  
  def legacy_ids
    @data.map { |r| r['legacy_id'] }.compact
  end

  def compare(force=false)
    compare_hashes(legacy_ids, force)
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
    puts "#{row['legacy_id'].to_s.ljust(10)} #{name_for(row).to_s.ljust(40)} #{new ? '(new)' : '     '}"
    if DEBUG
      puts row.values_hash(@attributes)
      puts row['remote_hash']
    end
  end
  
  def confirm
    agree('Do you want to continue, pushing these records to OneBody? ')
  end
  
  # use ActiveResource to create/update records on remote end
  def push
    puts 'Updating remote end...'
    index = 0
    print "#{resource.name} 0/0\r"; STDOUT.flush
    (@create + @update).each_slice(MAX_TO_BATCH_AT_A_TIME) do |records|
      response = resource.post(:batch, {}, records.to_xml)
      statuses = Hash.from_xml(response.body)['records']
      statuses.select { |s| s['status'] == 'error' }.each do |status|
        puts "#{status['legacy_id']}: #{status['error']}"
      end
      index += records.length
      print "#{resource.name} #{index}/#{@create.length + @update.length}\r"; STDOUT.flush
    end
    puts
  end
  
  def data_by_id
    @data_by_id ||= begin
      by_id = {}
      @data.each { |r| by_id[r['legacy_id'].to_i] = r }
      by_id
    end
  end

  attr_accessor :attributes, :data
  attr_reader :update, :create
  
  class << self; attr_accessor :resource; end
  def resource; self.class.resource; end
  
  protected
  
  # ask remote end for value hashe for each record (50 at a time) 
  # mark records to create or update based on response
  def compare_hashes(ids, force=false)
    ids.each_slice(MAX_HASHES_AT_A_TIME) do |some_ids|
      print '.'; STDOUT.flush
      options = {:attrs => @attributes.join(','), :legacy_id => some_ids.join(',')}
      options.merge!(:debug => true) if DEBUG
      hashes = resource.get(:hashify, options)
      hashes.each do |record|
        row = data_by_id[record['legacy_id'].to_i]
        row['remote_hash'] = record['hash'] if DEBUG
        @update << row if force or row.values_hash(@attributes) != record['hash']
      end
      @create += some_ids.reject { |id| hashes.map { |h| h['legacy_id'].to_i }.include?(id.to_i) }.map { |id| data_by_id[id] }
    end
    puts
  end
end

# handles people.csv and splits out family data for FamilyUpdater
class PeopleUpdater < UpdateAgent
  self.resource = Person
  
  # split out family data and create a new FamilyUpdater
  def initialize(filename)
    super(filename)
    person_data = []
    family_data = {}
    @data.each_with_index do |row, index|
      person, family = split_change_hash(row)
      if existing_family = family_data[family['legacy_id']]
        person['family'] = existing_family
        person_data << person
      else
        person['family'] = family
        person_data << person
        family_data[family['legacy_id']] = family
      end
      print "splitting family record #{index+1}\r"
    end
    puts
    @data = person_data
    @attributes.reject! { |a| a =~ /^family_/ and a != 'family_id' }
    @family_agent = FamilyUpdater.new(family_data.values)
  end
  
  def name_for(row)
    "#{row['first_name']} #{row['last_name']}"
  end
  
  def compare(force=false)
    @family_agent.compare(force)
    super(force)
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

  options = {:confirm => true, :force => false}
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby updateagent.rb [options] path/to/people.csv"
    opts.on("-y", "--no-confirm", "Assume 'yes' to any questions") do |v|
      options[:confirm] = false
    end
    opts.on("-l", "--log LOGFILE", "Output to log rather than stdout") do |log|
      $stdout = $stderr = File.open(log, 'a')
    end
    opts.on("-f", "--force", "Force update all records") do |f|
      options[:force] = true
    end
  end
  opt_parser.parse!
  
  if ARGV[0] # path/to/people.csv
    puts "Update Agent running at #{Time.now.strftime('%m/%d/%Y %I:%M %p')}"
    agent = PeopleUpdater.new(ARGV[0])
    puts "comparing records..."
    agent.compare(options[:force])
    if agent.has_work?
      if options[:confirm]
        case ask("#{agent.create.length + agent.update.length} record(s) to push. Continue? (Yes, No, Review) ") { |q| q.in = %w(yes no review y n r) }
        when 'review', 'r'
          agent.present
          unless agent.confirm
            puts "Canceled by user\n"
            exit
          end
        when 'no', 'n'
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
