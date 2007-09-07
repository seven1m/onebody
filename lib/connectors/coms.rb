# Coms Connector
# run with: script/sync coms path/to/comsdata

# This connector is used by Cedar Ridge Christian Church to connect with
# an old system written in FoxPro called COMS. If writing a connector for
# your own external database, please note it might not be nearly this
# complicated. Some voodoo is done here because of the nature of working
# with the COMS database and tools we have to do it.

# Refer to base.rb in this directory for a template connector

require File.dirname(__FILE__) + '/base'
require 'rubygems'
require 'dbf'

class ComsConnector < ExternalDataConnector
  BEG_CLASS_WEEK_NUM = 25
  
  def initialize(db_path)
    # set up database tables
    @db = {}
    {
    # name            filename        in memory
      :people =>     ['ssmember.DBF', false],
      :postal =>     ['sspostal.DBF', true ],
      :phone =>      ['ssphone.DBF',  true ],
      :categories => ['sscatcod.DBF', false],
      :classes =>    ['sswclass.DBF', false],
      :board =>      ['ssboard.DBF',  false],
      :service =>    ['sservice.DBF', false],
      :families =>   ['ssfamily.DBF', false]
    }.each do |name, details|
      file, in_memory = details
      @db[name] = DBF::Table.new(File.join(db_path, file), :in_memory => in_memory)
    end

    precache_class_data
    
    nil
  end
  
  def people_ids
    unless @people_ids
      @people_ids = []
      @db[:people].each_record do |record|
        if not (record.deceased or record.info_5 =~ /deny/i or record.familyname =~ /church$/i)
          @people_ids << record.memberid
        end
      end
    end
    @people_ids
  end
  
  def family_ids
    unless @family_ids
      @family_ids = []
      @db[:families].each_record do |record|
        if record.familyname !~ /church$/i
          @family_ids << record.familyid }
        end
      end
    end
    @family_ids
  end
  
  def each_person(updated_since)
    updated_since -= 1.day # because the COMS update time is a date only (time is midnight)
    people_ids # get all ids for completion reporting
    index = 0
    @db[:people].each_record do |record|
      new_data = false
      if not (record.deceased or record.info_5 =~ /deny/i or record.familyname =~ /church$/i)
        print "\r%.02f%% complete" % (index/@people_ids.length.to_f*100.0/2.0)
        member_phone_record = @db[:phone].find(:first, 'MEMBERID' => record.memberid)
        new_data = true if member_phone_record and member_phone_record.updates > updated_since
        family_phone_record = @db[:phone].find(:first, 'FAMILYID' => record.familyid)
        new_data = true if family_phone_record and family_phone_record.updates > updated_since
        classes = []
        @classes[record.memberid].to_a.each do |class_cat, updates|
          new_data = true if updates > updated_since
          classes << class_cat
        end
        can_sign_in = %w(M A P Y O C V).include?(record.mailgroup) or record.info_5 =~ /allow/i
        new_data = true if record.updates > updated_since
        if new_data
          yield({
            :legacy_id => record.memberid,
            :legacy_family_id => record.familyid,
            :sequence => record.fam_seq,
            :gender => record.sex,
            :first_name => record.nickname || record.first,
            :last_name => record.last =~ /,\s/ ? record.last.split(', ').first : record.last,
            :suffix => record.last =~ /,\s/ ? record.last.split(', ').last : nil,
            :mobile_phone => get_phone('CELLULAR', 'CELL_EXT', 'CELL_UNL', [member_phone_record, family_phone_record]),
            :work_phone => get_phone('WORKPHONE', 'WORK_EXT', 'WORK_UNL', [record]),
            :fax => get_phone('FAX', 'FAX_EXT', 'FAX_UNL', [member_phone_record, family_phone_record]),
            :birthday => to_datetime(record.birthday),
            :email => (e = record.email.to_s.strip.downcase).any? ? e : nil,
            :classes => classes.to_a.join(','),
            :mail_group => record.mailgroup == '(None)' ? nil : record.mailgroup,
            :anniversary => to_datetime(record.weddate),
            :member => %w(M A C).include?(record.mailgroup),
            :staff => record.email =~ /@cedarridgecc\.com$/,
            :elder => classes =~ /[\b,]EL[\b,]/,
            :deacon => false,
            :can_sign_in => can_sign_in,
            :visible_to_everyone => can_sign_in,
            :visible_on_printed_directory => %w(M A).include?(record.mailgroup),
            :full_access => (%w(M A C).include?(record.mailgroup) or record.info_5 =~ /allow/i)
          })
        end
        index += 1
      end
    end
    nil
  end
  
  def each_family(updated_since)
    updated_since -= 1.day # because the COMS update time is a date only (time is midnight)
    family_ids
    index = 0
    @db[:families].each_record do |record|
      new_data = false
      if record.familyname !~ /church$/i
        print "\r%.02f%% complete" % (index/@family_ids.length.to_f*100.0/2.0+50.0)
        family_phone_record = @db[:phone].find(:first, 'FAMILYID' => record.familyid)
        new_data = true if family_phone_record and family_phone_record.updates > updated_since
        family_postal_record = @db[:postal].find(:first, 'FAMILYID' => record.familyid)
        new_data = true if family_postal_record and family_postal_record.updates > updated_since
        new_data = true if record.updates > updated_since
        if new_data
          yield({
            :legacy_id => record.familyid,
            :name => record.familyname,
            :last_name => record.last =~ /,\s/ ? record.last.split(', ').first : record.last,
            :suffix => record.last =~ /,\s/ ? record.last.split(', ').last : nil,
            :address1 => family_postal_record ? family_postal_record.address1 : nil,
            :address2 => family_postal_record ? family_postal_record.address2 : nil,
            :city => family_postal_record ? family_postal_record.city : nil,
            :state => family_postal_record ? family_postal_record.state : nil,
            :zip => family_postal_record ? family_postal_record.zip.to_s[0..9] : nil,
            :home_phone => get_phone('HOMEPHONE', nil, 'UNLISTED', [family_phone_record]),
            :email => (e = record.internet.to_s.strip.downcase).any? ? e : nil,
            :mail_group => record.mailpick == '(None)' ? nil : record.mailpick
          })
        end
        index += 1
      end
    end
    print "\r100.00% complete\n"
    nil
  end
  
  private
    # hocus pocus to build a complete phone number from a series of records + columns
    # each record is tried in order to get the desired outcome
    # if the number is unlisted, the next record is tried
    def get_phone(phone_attr, ext_attr, unlisted_attr, records)
      phone = nil
      while records.any?
        record = records.shift
        if (
          record and
          (not unlisted_attr or not record.attributes[unlisted_attr]) and
          p = record.attributes[phone_attr] and
          p.gsub(/\s/, '').length >= 7
        )
          phone = p
          phone += ' ' + record.attributes[ext_attr].to_s if record.attributes[ext_attr].to_s.any?
          break
        end
      end
      return phone
    end
    
    def precache_class_data
      logger.info 'loading class attendance/membership data'
      logger.info '  categories'
      @class_cats = []
      @board_cats = []
      @service_cats = []
      @db[:categories].each_record do |record|
        case record.modulename
        when 'CA-CLAS-CATE'
          @class_cats << record.category
        when 'CA-BOAR-CATE'
          @board_cats << record.category
        when 'CA-SERV-CATE'
          @service_cats << record.category
        end
      end
      
      @classes = {}
      logger.info '  classes'
      years = [Date.today.year.to_s, (Date.today.year-1).to_s]
      @db[:classes].each_record do |record|
        @classes[record.memberid] ||= []
        if @class_cats.include?(record.category) and years.include?(record.year.to_s)
          @classes[record.memberid] << [record.category, record.updates]
        end
      end
      logger.info '  board'
      @db[:board].each_record do |record|
        @classes[record.memberid] ||= []
        if @board_cats.include?(record.category) and record.category !~ /^[0-9]/
          @classes[record.memberid] << [record.category, record.updates]
        end
      end
      logger.info '  service'
      @db[:service].each_record do |record|
        @classes[record.memberid] ||= []
        if @service_cats.include?(record.category)
          @classes[record.memberid] << [record.category, record.updates]
        end
      end
    end

    def to_datetime(time)
      if time
        DateTime.new(time.year, time.month, time.day) rescue nil
      end
    end
end

module DBF
  class Record
    private
    # fix bug in DBF code (or workaround bug in Coms dbf files; I don't know :-)
    def initialize_values(columns)
      columns.each do |column|
        case column.type
        when 'I' # added by Tim - I don't understand this much, but it seems to work
          @attributes[column.name] = @data.read(column.length).unpack("I").first
        when 'N' # number
          @attributes[column.name] = column.decimal.zero? ? unpack_string(column).to_i : unpack_string(column).to_f
        when 'D' # date
          raw = unpack_string(column).strip
          unless raw.empty?
            begin
              parts = raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i}
              @attributes[column.name] = Time.gm(*parts)
            rescue
              parts = raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i}
              @attributes[column.name] = Date.new(*parts)
            end
          end
        when 'M' # memo
          starting_block = unpack_string(column).to_i
          @attributes[column.name] = read_memo(starting_block)
        when 'L' # logical
          @attributes[column.name] = unpack_string(column) =~ /^(y|t)$/i ? true : false
        else
          @attributes[column.name] = unpack_string(column).strip
        end
      end
    end
    # don't know why, but accessors stopped working for me.
    def define_accessors
      @table.columns.each do |column|
        underscored_column_name = underscore(column.name)
        if @table.options[:accessors]
          self.class.send :define_method, underscored_column_name do
            @attributes[column.name]
          end
          @@accessors_defined = true
        end
      end
    end
  end
  class Table
    # more efficient iterator (so we don't load everything)
    def each_record
      if options[:in_memory] and @records
        @records.each { |r| yield(r) }
      else
        0.upto(@record_count - 1) do |n|
          seek_to_record(n)
          yield(DBF::Record.new(self)) unless deleted_record?
        end
      end
    end
  end
end
