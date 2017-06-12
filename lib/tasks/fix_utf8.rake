# encoding: utf-8

# credit: http://markmcb.com/2011/11/07/replacing-ae%E2%80%9C-ae%E2%84%A2-aeoe-etc-with-utf-8-characters-in-ruby-on-rails/

namespace :onebody do
  desc 'Fix utf8 encoding errors in text.'
  task fix_utf8: :environment do
    replacements = [
      ['â€¦', '…'],          # elipsis
      ['â€“', '–'],          # long hyphen
      ['â€”', '–'],          # long hyphen
      ['â€™', '’'],          # curly apostrophe
      ['â€˜', "'"],          # straight apostrophe
      ['â€œ', '“'],          # curly open quote
      [/â€[[:cntrl:]]/, '”'] # curly close quote
    ]
    klasses = {
      'Album'         => %w(description),
      'Comment'       => %w(text),
      'Message'       => %w(body html_body),
      'NewsItem'      => %w(title body),
      'Note'          => %w(body),
      'Page'          => %w(body),
      'Person'        => %w(about testimony business_description),
      'PrayerRequest' => %w(request answer),
      'StreamItem'    => %w(body),
      'Verse'         => %w(text)
    }

    Site.each do |site|
      puts "Site #{site.name}"
      klasses.each do |klass, attributes|
        index = 0
        count = Kernel.const_get(klass).count
        print "  #{klass} 0 of #{count}\r"
        Kernel.const_get(klass).find_each do |obj|
          index += 1
          print "  #{klass} #{index} of #{count}\r"
          attributes.each do |attribute|
            next unless obj[attribute]
            replacements.each do |set|
              obj[attribute] = obj[attribute].gsub(set[0], set[1])
            end
          end
          obj.save(validate: false) if obj.changed?
        end
        puts
      end
    end
  end
end
