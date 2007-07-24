require File.dirname(__FILE__) + '/base'
require 'dbf'

class Coms < ExternalDataConnector
  BEG_CLASS_WEEK_NUM = 25
  
  attr_accessor :db
  
  def initialize(db_path)
    # set up database tables
    @db = {}
    {
      :people => 'ssmember',
      :postal => 'sspostal',
      :phone => 'ssphone',
      :categories => 'sscatcod',
      :classes => 'sswclass',
      :board => 'ssboard',
      :service => 'sservice',
      :families => 'ssfamily'
    }.each do |name, file|
      @db[name] = DBF::Table.new(File.join(db_path, file + '.dbf'), :in_memory => false)
    end
    
    # category stuff (used to get classes)
    @class_cats = []
    @board_cats = []
    @service_cats = []
    @db[:categories].records.each do |record|
      case record.modulename
      when 'CA-CLAS-CATE'
        @class_cats << record.category
      when 'CA-BOAR-CATE'
        @board_cats << record.category
      when 'CA-SERV-CATE'
        @service_cats << record.category
      end
    end
  end
  
  def each_person
    @db[:people].records[600..605].each do |record|
      if not (record.deceased or record.info_5 =~ /deny/i or record.familyname =~ /church$/i)
        member_phone_record = db[:phone].find(:first, 'MEMBERID' => record.memberid)
        family_phone_record = db[:phone].find(:first, 'FAMILYID' => record.familyid)
        yield({
          :family_id => record.familyid,
          :sequence => record.fam_seq,
          :gender => record.sex,
          :first_name => record.nickname || record.first,
          :last_name => record.last =~ /,\s/ ? record.last.split(', ').first : record.last,
          :suffix => record.last =~ /,\s/ ? record.last.split(', ').last : nil,
          :mobile_phone => get_phone('CELLULAR', 'CELL_EXT', 'CELL_UNL', [member_phone_record, family_phone_record]),
          :work_phone => get_phone('WORKPHONE', 'WORK_EXT', 'WORK_UNL', [record]),
          :fax => get_phone('FAX', 'FAX_EXT', 'FAX_UNL', [member_phone_record, family_phone_record]),
          :birthday => record.birthday,
          :email => record.email,
          :classes => get_classes(record.memberid),
          :mail_group => record.mailgroup,
          :anniversary => record.weddate,
          :member => record.mailgroup ..................
        })
      end
    end
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
          not record.attributes[unlisted_attr] and
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
    
    def get_classes(memberid)
      years = [Date.today.year.to_s, (Date.today.year-1).to_s]
      #week_num = Date.today.yday / 7 + 1
      #weeks = (week_num > BEG_CLASS_WEEK_NUM ? BEG_CLASS_WEEK_NUM..week_num : 1..week_num).map { |w| "wk%02d=1" % w }.join(' or ')

      classes = []
      classes << @db[:classes].find(:all, 'MEMBERID' => memberid).map do |record|
        years.include?(record.year.to_s) and @class_cats.include?(record.category)
      end
      classes << @db[:board].find(:all, 'MEMBERID' => memberid).map do |record|
        record.category !~ /^[0-9]/ and @board_cats.include?(record.category)
      end
      classes << @db[:service].find(:all, 'MEMBERID' => memberid).map do |record|
        @service_cats.include?(record.category)
      end
      
      classes.join(',')
    end
end

# legacy (python) code:
<<-EOF
debug = 0

source_dsn = "COMS"
destination_dsn = "crccweb2"

geo_url = "http://rpc.geocoder.us/service/csv?address=%s"
max_geo_queries = 1000

from ado import odbc
import urllib
import time
import re

week_num = time.localtime()[7] / 7 + 1

def main():
    last_update = mktime(file('crfupdates.txt', 'r').read())
    source = odbc(source_dsn)
    destination = odbc(destination_dsn)
    print "Retrieving people from COMS..."
    members = source.query("select memberid, familyid, familyname, first, nickname, last, email, birthday, weddate, fam_seq, mailgroup, info_1, sex, workphone, work_unl, work_ext, updates, info_5 from ssmember where deceased = 0 and info_5 not like '%deny%'", ["memberid", "familyid", "familyname", "first", "nickname", "last", "email", "birthday", "weddate", "fam_seq", "mailgroup", "info_1", "sex", "workphone", "work_unl", "work_ext", "updates", "info_5"])
    members = [member for member in members if member["familyname"].lower().find("church") == -1]
    print "Adding and updating families and people..."
    num_coord_queries = 0
    index = 0
    next_pct = 1.0
    for member in members:
        if debug: print "member id:", member["memberid"]
        member["email"] = member["email"].lower()
        if member["last"].find(',') > -1:
            last_name, suffix = member["last"].split(', ')
        else:
            last_name, suffix = member["last"], None
        address = source.query("select address1, address2, city, state, zip from sspostal where familyid = %s" % member["familyid"], ["address1", "address2", "city", "state", "zip"])[0]
        fp = source.query("select ~ from ssphone where familyid = %s" % member["familyid"], ["homephone", "unlisted", "cellular", "cell_unl", "cell_ext", "fax", "fax_unl", "fax_ext"])[0]
        try: pp = source.query("select ~ from ssphone where memberid = %s" % member["memberid"], ["homephone", "unlisted", "cellular", "cell_unl", "cell_ext", "fax", "fax_unl", "fax_ext"])[0]
        except: pp = None
        home_phone = get_phone(fp, pp, 'unlisted', 'homephone')
        mobile_phone = get_phone(pp, fp, 'cell_unl', 'cellular', 'cell_ext')
        work_phone = get_phone(member, None, 'work_unl', 'workphone', 'work_ext')
        fax = get_phone(pp, fp, 'fax_unl', 'fax', 'fax_ext')

        family = source.query("select familyname, last, internet, svname, mailpick, updates from ssfamily where familyid = %s" % member["familyid"], ["familyname", "last", "internet", "svname", "mailpick", "updates"])[0]
        family_name = family["familyname"]
        family_last_name = family["last"]
        if family_last_name.find(',') > -1:
            family_last_name = family_last_name.split(',')[0]
        family_email = family["internet"]

        # fix names with characters not supported by Coms
        #if family_name == 'Ed & Sherry Munoz':
        #    family_name = "Ed & Sherry Mu\303\261oz"
        #    family_last_name = "Mu\303\261oz"
        #if last_name == 'Munoz':
        #    last_name = "Mu\303\261oz"

        try:
            birthday = quote(member["birthday"].Format("%Y/%m/%d"))
        except ValueError:
            birthday = 'NULL'
        else:
            if birthday.find('1899') > -1: birthday = 'NULL'
        try:
            anniversary = quote(member["weddate"].Format("%Y/%m/%d"))
        except ValueError:
            anniversary = 'NULL'
        else:
            if anniversary.find('1899') > -1: anniversary = 'NULL'

        mailgroup = member["mailgroup"]
        if mailgroup == '(None)': mailgroup = ''

        family_mailgroup = family["mailpick"]
        if family_mailgroup == '(None)': family_mailgroup = ''

        year = time.localtime()[0]
        beg_week = 25
        weeks = []
        for num in range(beg_week, week_num+1) or range(1, week_num+1):
            weeks.append("wk%02d=1" % num)
        weeks = " or ".join(weeks)
        if debug: print weeks

        class_cats = [c['category'] for c in source.query("select category from sscatcod where modulename='CA-CLAS-CATE'", ['category'])]
        board_cats = [c['category'] for c in source.query("select category from sscatcod where modulename='CA-BOAR-CATE'", ['category'])]
        service_cats = [c['category'] for c in source.query("select category from sscatcod where modulename='CA-SERV-CATE'", ['category'])]

        classes = [c["category"] for c in source.query("select category from sswclass where memberid=%s and (year=%s or year=%s) and (1=1 or (%s))" % (member["memberid"], quote(year), quote(year-1), weeks), ["category"]) if c['category'] in class_cats]
        classes = classes + [c["category"] for c in source.query("select category from ssboard where memberid=%s" % (member["memberid"]), ["category"]) if c["category"][0] not in "0123456789" and c['category'] in board_cats]
        classes = classes + [c["category"] for c in source.query("select category from sservice where memberid=%s" % (member["memberid"]), ["category"]) if c['category'] in service_cats]
        classes = ','.join(classes)
        if debug: print classes

        if 1 or mktime(family["updates"].Format("%Y/%m/%d")) >= last_update:
            if not destination.query("select id from families where legacy_id=%s" % member["familyid"], ['id']):
                query = "insert into families set legacy_id=%s" % (member["familyid"])
                if debug: print query
                else: destination.query(query)
            query = "update families set name=%s, last_name=%s, address1=%s, address2=%s, city=%s, state=%s, zip=%s, home_phone=%s, email=%s, mail_group=%s where legacy_id = %s" % (quote(family_name), quote(family_last_name), quote(address["address1"]), quote(address["address2"]), quote(address["city"]), quote(address["state"]), quote(address["zip"]), home_phone, quote(family_email), quote(family_mailgroup), member["familyid"])
            if debug: print query
            else: destination.query(query)

        if 1 or mktime(member["updates"].Format("%Y/%m/%d")) >= last_update:
            if not destination.query("select id from people where legacy_id=%s" % member["memberid"], ['id']):
                query = "insert into people set legacy_id=%s" % (member["memberid"])
                if debug: print query
                else: destination.query(query)
            try:
                family_id = destination.query("select id from families where legacy_id=%s" % member["familyid"], ['id'])[0]['id']
            except:
                query = "delete from people where legacy_id=%s" % member["memberid"]
                if debug: print query
                else: destination.query(query)
            else:
                query = "update people set family_id=%s, sequence=%s, gender=%s, first_name=%s, last_name=%s, mobile_phone=%s, work_phone=%s, fax=%s, birthday=%s, anniversary=%s, classes=%s, shepherd=%s, mail_group=%s, suffix=%s, flags=%s where legacy_id = %s" % (family_id, member["fam_seq"], quote(member["sex"]), quote(member["nickname"] or member["first"]), quote(last_name), mobile_phone, work_phone, fax, birthday, anniversary, quote(classes), quote(member["info_1"]), quote(mailgroup), quote(suffix), quote(member["info_5"]), member["memberid"])
                if debug: print query
                else: destination.query(query)
    
            if not destination.query("select email_changed from people where legacy_id=%s and email_changed=1" % member["memberid"], ['email_changed']):
                query = "update people set email=%s where legacy_id = %s" % (quote(member["email"]), member["memberid"])
                if debug: print query
                else: destination.query(query)

            email = destination.query("select email from people where legacy_id=%s and email_changed=1" % member["memberid"], ['email'])
            if email and email[0]['email'].lower() == member["email"].lower():
                query = "update people set email_changed=0 where legacy_id = %s" % member["memberid"]
                if debug: print query
                else: destination.query(query)

        index += 1
        pct = index / float(len(members)) * 100
        if pct >= next_pct:
            print "%s%% complete" % int(pct)
            next_pct += 1.0

    print "Deleting old families and people..."

    query = "delete from people where legacy_id not in (%s)" % ','.join([str(m['memberid']) for m in members])
    if debug: print query
    else: destination.query(query)

    query = "delete from families where legacy_id not in (%s)" % ','.join([str(m['familyid']) for m in members])
    if debug: print query
    else: destination.query(query)

    file('crfupdates.txt', 'w').write(time.strftime('%Y/%m/%d'))

    print
    print "Finished"

def mktime(date):
    return time.mktime(time.strptime(date, '%Y/%m/%d'))

def get_phone(primary, secondary, unlisted, main, ext=None):
    phone = ''
    if primary and not primary[unlisted]:
        phone = primary[main]
        if ext and primary[ext]: phone += ' ' + primary[ext]
    if len(phone.replace(' ', '')) < 6 and secondary and not secondary[unlisted]:
        phone = secondary[main]
        if ext and secondary[ext]: phone += ' ' + secondary[ext]
    return ints_only(phone)

digit = re.compile(r"\d")
def ints_only(string):
    try: return int(''.join(digit.findall(string)))
    except: return 'NULL'

def quote(value):
    if value == None: return 'NULL'
    value = str(value)
    return "'" + value.replace("'", "''") + "'"

if __name__ == "__main__":
    main()
EOF

# fix bug in DBF code (or workaround bug in Coms dbf files; I don't know :-)
module DBF
  class Record
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
  end
end