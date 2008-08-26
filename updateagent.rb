#!/usr/bin/env ruby

SITE       = 'http://localhost:3000'
USER_EMAIL = 'admin@example.com'
USER_KEY   = 'dafH2KIiAcnLEr5JxjmX2oveuczq0R6u7Ijd329DtjatgdYcKp'

require 'csv'
require 'rubygems'
require 'activeresource'
require 'digest/sha1'

class Base < ActiveResource::Base
  self.site     = SITE
  self.user     = USER_EMAIL
  self.password = USER_KEY
end

class Person < Base; end
class Family < Base; end

class Hash
  def values_hash(*attrs)
    attrs = attrs.first if attrs.first.is_a?(Array)
    values = attrs.map do |attr|
      value = self[attr.to_s]
      value.respond_to?(:strftime) ? value.strftime('%Y%m%d%H%M') : value
    end
    Digest::SHA1.hexdigest(values.to_s)
  end
end

class UpdateAgent
  def initialize(filename)
    schema = resource.find(:first).attributes
    csv = CSV.open(filename, 'r')
    @attributes = csv.shift
    @data = csv.map do |row|
      hash = {}
      row.each_with_index do |value, index|
        key = @attributes[index]
        if [true, false].include?(schema[key])
          value = !['false', 'no', '0'].include?(value)
        elsif schema[key].respond_to?(:strftime)
          value = value.strftime('%Y%m%d%H%M')
        end
        hash[key] = value
      end
      hash
    end
    @create = []
    @update = []
  end
  
  def ids
    @data.map { |r| r['id'] }.compact
  end
  
  def legacy_ids
    @data.map { |r| r['legacy_id'] }.compact
  end

  def compare
    ids.each_slice(50) do |slice_ids|
      resource.get(:hashify, :ids => slice_ids, :attrs => @attributes).each do |record|
        row = @data.detect { |r| r['id'] == record['id'] }
        if record['exists']
          @update << row if row.values_hash(@attributes) != record['hash']
        else
          @create << row
        end
      end
    end
  end
  
  class << self; attr_accessor :resource; end
  def resource; self.class.resource; end
end

class PeopleUpdater < UpdateAgent
  self.resource = Person
end

if __FILE__ == $0
  if ARGV[0] and ARGV[1]
    agent = PeopleUpdater.new(ARGV[0])
    agent
  else
    puts 'Usage: ruby updateagent.rb people.csv families.csv'
  end
end