# CSV Connector
# requires two CSV files -- one for people, one for families
# each person must link to a family in families.csv
# example families.csv and people.csv files in this directory

# run with: script/sync csv /path/to/people.csv /path/to/families.csv

require File.dirname(__FILE__) + '/base'
require 'csv'

class CsvConnector < ExternalDataConnector
  def initialize(people_file, families_file)
    @people_file = people_file
    @families_file = families_file
  end
  
  def people_ids
    ids = []
    CSV.open(@people_file, 'r') do |row|
      ids << row[0] unless row[0] == 'legacy_id'
    end
    return ids
  end
  
  def family_ids
    ids = []
    CSV.open(@families_file, 'r') do |row|
      ids << row[0] unless row[0] == 'legacy_id'
    end
    return ids
  end

  def each_person(updated_since)
    CSV.open(@people_file, 'r') do |row|
      hash = {}
      %w(legacy_id legacy_family_id
         sequence gender
         first_name last_name suffix
         mobile_phone work_phone fax
         birthday anniversary
         email
         classes mail_group
         member staff elder deacon
         can_sign_in visible_to_everyone visible_on_printed_directory full_access
      ).each_with_index do |field, index|
        next if row[0] == 'legacy_id'
        hash[field.to_sym] = row[index]
      end
      yield(hash)
    end
  end
  
  def each_family(updated_since)
    CSV.open(@families_file, 'r') do |row|
      hash = {}
      %w(legacy_id
         name last_name suffix
         address1 address2 city state zip
         home_phone
         email
         mail_group
      ).each_with_index do |field, index|
        next if row[0] == 'legacy_id'
        hash[field.to_sym] = row[index]
      end
      yield(hash)
    end
  end
end