# Coms to CSV
# run with: ruby coms_to_csv.rb path/to/comsdata out.csv

require 'csv'
require 'rubygems'
require 'dbf'

class ComsToCsv
  BEG_CLASS_WEEK_NUM = 25
  
  def initialize(db_path, output_filename)
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
    precache_family_data
    
    write_to_csv(output_filename)
  end
  
  def write_to_csv(filename)
    puts 'writing to csv'
    file = File.open(filename, 'wb')
    header_written = false
    CSV::Writer.generate(file) do |csv|
      each_person do |person|
        next unless family_hash = @families[person['legacy_family_id'].to_i]
        family_hash.each do |attribute, value|
          person['family_' + attribute] = value
        end
        unless header_written
          csv << person.keys.sort
          header_written = true
        end
        csv << person.keys.sort.map { |key| person[key] }
      end
    end
    file.close
  end
  
  def each_person
    index = 0
    @db[:people].each_record do |record|
      if not (record.deceased or record.info_5 =~ /deny/i or record.familyname =~ /church$/i)
        print "loading people #{index+1}\r"
        member_phone_record = @db[:phone].find(:first, 'MEMBERID' => record.memberid)
        family_phone_record = @db[:phone].find(:first, 'FAMILYID' => record.familyid)
        classes = []
        @classes[record.memberid].to_a.each do |class_cat, updates|
          classes << class_cat
        end
        can_sign_in = %w(M A P Y O C V).include?(record.mailgroup) or record.info_5 =~ /allow/i
        birthday = to_datetime(record.birthday)
        anniversary = to_datetime(record.weddate)
        yield({
          'legacy_id' => record.memberid,
          'legacy_family_id' => record.familyid,
          'sequence' => record.fam_seq,
          'gender' => record.sex,
          'first_name' => record.nickname || record.first,
          'last_name' => record.last =~ /,\s/ ? record.last.split(', ').first : record.last,
          'suffix' => record.last =~ /,\s/ ? record.last.split(', ').last : nil,
          'mobile_phone' => get_phone('CELLULAR', 'CELL_EXT', 'CELL_UNL', [member_phone_record, family_phone_record]),
          'work_phone' => get_phone('WORKPHONE', 'WORK_EXT', 'WORK_UNL', [record]),
          'fax' => get_phone('FAX', 'FAX_EXT', 'FAX_UNL', [member_phone_record, family_phone_record]),
          'birthday' => birthday ? birthday.strftime('%m/%d/%Y') : nil,
          'email' => (e = record.email.to_s.strip.downcase).any? ? e : nil,
          'classes' => classes.to_a.join(','),
          'mail_group' => record.mailgroup == '(None)' ? nil : record.mailgroup,
          'anniversary' => anniversary ? anniversary.strftime('%m/%d/%Y') : nil,
          'member' => (record.date1 and not %w(N F).include?(record.mailgroup)),
          'staff' => record.email =~ /@cedarridgecc\.com$/,
          'elder' => classes =~ /[\b,]BEL[\b,]/,
          'deacon' => false,
          'can_sign_in' => can_sign_in,
          'visible_to_everyone' => can_sign_in,
          'visible_on_printed_directory' => %w(M A).include?(record.mailgroup),
          'full_access' => (%w(M A C).include?(record.mailgroup) or record.info_5 =~ /allow/i),
          'can_pick_up' => record.info_10,
          'cannot_pick_up' => record.info_11,
          'medical_notes' => record.info_12,
          'barcode_id' => record.memberid
        })
        index += 1
      end
    end
    puts
  end
  
  def each_family
    index = 0
    @db[:families].each_record do |record|
      if record.familyname !~ /church$/i
        print "loading families #{index+1}\r"
        family_phone_record = @db[:phone].find(:first, 'FAMILYID' => record.familyid)
        family_postal_record = @db[:postal].find(:first, 'FAMILYID' => record.familyid)
        yield({
          'legacy_id' => record.familyid,
          'name' => record.familyname,
          'last_name' => record.last =~ /,\s/ ? record.last.split(', ').first : record.last,
          'address1' => family_postal_record ? family_postal_record.address1 : nil,
          'address2' => family_postal_record ? family_postal_record.address2 : nil,
          'city' => family_postal_record ? family_postal_record.city : nil,
          'state' => family_postal_record ? family_postal_record.state : nil,
          'zip' => family_postal_record ? family_postal_record.zip.to_s[0..9] : nil,
          'home_phone' => get_phone('HOMEPHONE', nil, 'UNLISTED', [family_phone_record]),
          'email' => (e = record.internet.to_s.strip.downcase).any? ? e : nil
        })
        index += 1
      end
    end
    puts
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
    
    def precache_family_data
      @families = {}
      each_family do |family|
        @families[family['legacy_id'].to_i] = family
      end
    end
    
    def precache_class_data
      @class_cats = []
      @board_cats = []
      @service_cats = []
      index = 0
      @db[:categories].each_record do |record|
        print "loading categories #{index+1}\r"
        case record.modulename
        when 'CA-CLAS-CATE'
          @class_cats << record.category
        when 'CA-BOAR-CATE'
          @board_cats << record.category
        when 'CA-SERV-CATE'
          @service_cats << record.category
        end
        index += 1
      end
      puts
      
      @classes = {}
      years = [Date.today.year.to_s, (Date.today.year-1).to_s]
      index = 0
      @db[:classes].each_record do |record|
        print "loading classes #{index+1}\r"
        @classes[record.memberid] ||= []
        if @class_cats.include?(record.category) and years.include?(record.year.to_s)
          @classes[record.memberid] << ['C'+record.category, record.updates]
        end
        index += 1
      end
      puts
      
      index = 0
      @db[:board].each_record do |record|
        print "loading boards #{index+1}\r"
        @classes[record.memberid] ||= []
        if @board_cats.include?(record.category) and record.category !~ /^[0-9]/
          @classes[record.memberid] << ['B'+record.category, record.updates]
        end
        index += 1
      end
      puts
      
      index = 0
      @db[:service].each_record do |record|
        print "loading services #{index+1}\r"
        @classes[record.memberid] ||= []
        if @service_cats.include?(record.category)
          @classes[record.memberid] << ['S'+record.category, record.updates]
        end
        index += 1
      end
      puts
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

if $0 == __FILE__
  ComsToCsv.new(*ARGV)
end
