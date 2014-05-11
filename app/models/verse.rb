# coding: utf-8
require 'net/http'

class Verse < ActiveRecord::Base
  has_and_belongs_to_many :people, -> { where('people.visible' => true) }
  has_many :comments, dependent: :destroy
  belongs_to :site

  scope_by_site_id
  acts_as_taggable

  def admin?(person)
    self.people.include? person or person.admin?(:manage_verses)
  end

  def reference=(ref)
    write_attribute :reference, Verse.normalize_reference(ref)
    lookup
  end

  def to_param
    self.reference
  end

  def name; reference; end

  def title; reference; end

  def body; text; end

  def book_name
    @book_name ||= reference.gsub(/[\d\:\s\-;,]+$/, '')
  end

  # living stones (KJV, ASV, YLT, AKJV, WEB)
  LS_BASE_URL = 'http://www.seek-first.com/Bible.php?q=&passage=Seek'

  def lookup
    if Rails.env == 'test'
      self.translation = 'WEB'
      self.text = 'test'
      self.update_sortables
    else
      return if reference.nil? or reference.empty?
      self.translation = 'WEB' if translation.nil?
      url = LS_BASE_URL + '&p=' + URI.escape(reference) + '&version=' + translation
      result = Net::HTTP.get(URI.parse(url))
      url = /<!\-\-\s*(http:\/\/api\.seek\-first\.com.+?)\s*\-\->/.match(result)[1]
      result = Net::HTTP.get(URI.parse(url)).gsub(/\s+/, ' ').gsub(/ì|î/, '"').gsub(/ë|í/, "'").gsub('*', '')
      begin
         self.text = result.scan(/<Text>(.+?)<\/Text>/).map { |p| p[0].gsub(/<.+?>/, '').strip }.join(' ')
         # maybe not needed? - breaks in ruby 1.9
         #self.text.gsub!(/\223|\224/, '"')
         #self.text.gsub!(/\221|\222/, "'")
         #self.text.gsub!(/\227/, "--")
         self.update_sortables
      rescue
        nil
      end
    end
  end

  def lookup!
    lookup
    save
  end

  def update_sortables
    self.book = Verse::BOOKS.index(self.book_name)
    self.chapter = self.reference.gsub(/^.\s*[^\d]*/, '').to_i
    self.verse = self.reference.split(':').last.to_i
  end

  def <=>(v)
    [book, chapter, verse] <=> [v.book, v.chapter, v.verse]
  end

  validates_presence_of :text, :reference
  validates_length_of :text, maximum: 1000, allow_nil: true, message: " is a bit too long. Please pick a shorter passage."

  BOOKS = [
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    'Joshua',
    'Judges',
    'Ruth',
    '1 Samuel',
    '2 Samuel',
    '1 Kings',
    '2 Kings',
    '1 Chronicles',
    '2 Chronicles',
    'Ezra',
    'Nehemiah',
    'Esther',
    'Job',
    'Psalms',
    'Proverbs',
    'Ecclesiastes',
    'Song of Solomon',
    'Isaiah',
    'Jeremiah',
    'Lamentations',
    'Ezekiel',
    'Daniel',
    'Hosea',
    'Joel',
    'Amos',
    'Obadiah',
    'Jonah',
    'Micah',
    'Nahum',
    'Habakkuk',
    'Zephaniah',
    'Haggai',
    'Zechariah',
    'Malachi',
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1 Corinthians',
    '2 Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1 Thessalonians',
    '2 Thessalonians',
    '1 Timothy',
    '2 Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1 Peter',
    '2 Peter',
    '1 John',
    '2 John',
    '3 John',
    'Jude',
    'Revelation',
  ]

  YOUVERSION_BOOKS = %w(
    gen exod lev num deut josh judg ruth 1sam 2sam 1kgs 2kgs 1chr 2chr ezra neh esth job ps prov eccl song isa jer lam ezek dan hos joel amos obad jonah mic nah hab zeph hag zech mal
    matt mark luke john acts rom 1cor 2cor gal eph phil col 1thess 2thess 1tim 2tim titus phlm heb jas 1pet 2pet 1john 2john 3john jude rev
  )

  BOOKS_AND_CHAPTERS = {
    'Genesis'         => 1..50,
    'Exodus'          => 1..40,
    'Leviticus'       => 1..27,
    'Numbers'         => 1..36,
    'Deuteronomy'     => 1..34,
    'Joshua'          => 1..24,
    'Judges'          => 1..21,
    'Ruth'            => 1..4,
    '1 Samuel'        => 1..31,
    '2 Samuel'        => 1..24,
    '1 Kings'         => 1..22,
    '2 Kings'         => 1..25,
    '1 Chronicles'    => 1..29,
    '2 Chronicles'    => 1..36,
    'Ezra'            => 1..10,
    'Nehemiah'        => 1..13,
    'Esther'          => 1..10,
    'Job'             => 1..42,
    'Psalms'          => 1..150,
    'Proverbs'        => 1..31,
    'Ecclesiastes'    => 1..12,
    'Song of Solomon' => 1..8,
    'Isaiah'          => 1..66,
    'Jeremiah'        => 1..52,
    'Lamentations'    => 1..5,
    'Ezekiel'         => 1..48,
    'Daniel'          => 1..12,
    'Hosea'           => 1..14,
    'Joel'            => 1..3,
    'Amos'            => 1..9,
    'Obadiah'         => 1..1,
    'Jonah'           => 1..4,
    'Micah'           => 1..7,
    'Nahum'           => 1..3,
    'Habakkuk'        => 1..3,
    'Zephaniah'       => 1..3,
    'Haggai'          => 1..2,
    'Zechariah'       => 1..14,
    'Malachi'         => 1..4,
    'Matthew'         => 1..28,
    'Mark'            => 1..16,
    'Luke'            => 1..24,
    'John'            => 1..21,
    'Acts'            => 1..28,
    'Romans'          => 1..16,
    '1 Corinthians'   => 1..16,
    '2 Corinthians'   => 1..13,
    'Galatians'       => 1..6,
    'Ephesians'       => 1..6,
    'Philippians'     => 1..4,
    'Colossians'      => 1..4,
    '1 Thessalonians' => 1..5,
    '2 Thessalonians' => 1..3,
    '1 Timothy'       => 1..6,
    '2 Timothy'       => 1..4,
    'Titus'           => 1..3,
    'Philemon'        => 1..1,
    'Hebrews'         => 1..13,
    'James'           => 1..5,
    '1 Peter'         => 1..5,
    '2 Peter'         => 1..3,
    '1 John'          => 1..5,
    '2 John'          => 1..1,
    '3 John'          => 1..1,
    'Jude'            => 1..1,
    'Revelation'      => 1..22
  }

  def youversion_url
    "http://www.youversion.com/bible/web/#{YOUVERSION_BOOKS[book || 0]}/#{chapter}/#{verse}"
  end

  def ebible_url
    "http://ebible.com/##{URI.encode(reference)}"
  end

  class << self

    def find(reference_or_id, options=nil)
      if reference_or_id.nil?
        nil
      elsif reference_or_id.is_a?(Symbol) or reference_or_id.to_s =~ /^\d+$/
        super
      else
        where(reference: reference_or_id).first
      end
    end

    def find_by_reference(reference)
      where(reference: Verse.normalize_reference(reference)).first_or_create
    end

    # make the reference normal (proper book name, formatting, etc.)
    # we'll assume only one book per reference
    def normalize_reference(reference)
      return nil unless reference
      book = normalize_book(reference.strip.downcase.match(/^.\s*[^\d]*/).to_s.strip)
      numbers = normalize_numbers(reference.gsub(/^.\s*[^\d]*/, ''))
      if book and numbers
        book + ' ' + numbers
      else
        nil
      end
    end

    def normalize_book(book)
      book.downcase!
      book[0..0] = '1' if book =~ /^i\s/
      book[0..1] = '2' if book =~ /^ii\s/
      book[0..2] = '3' if book =~ /^iii\s/
      if (index = BOOKS.map { |b| b.downcase }.index(book))
        BOOKS[index]
      else
        BOOKS.select { |b| b.downcase[0...book.length] == book }.first
      end
    end

    def normalize_numbers(numbers)
      numbers.gsub(/\s+/, '')
    end

    def combine_refs(refs)
      combined = refs.first
      refs[1..-1].each do |ref|
        if combined.index(ref.gsub(/\:.*$/, '')) == 0
          combined += ',' + /\:(.*)$/.match(ref)[1]
        elsif combined.index(ref.gsub(/\d+\:.*$/, '')) == 0
          combined += ';' + /\d+\:.*$/.match(ref)[0]
        else
          return nil # couldn't do it - fail *not* gracefully
        end
      end
      combined
    end

    LINK_URL = "http://bible.gospelcom.net/cgi-bin/bible?passage=%s&version=%s"

    def link_references_in_text(text)
      return unless text
      BOOKS.each do |book|
        text.gsub!(/(#{book}\s\d+(?::\d+)?(?:[\-,;](?:\d+:)?\d+)*)(?:\s\(([A-Z]+)\))?/) do |match|
          url = LINK_URL % [CGI.escape($1), $2 || 'NIV']
          '<a href="%s" class="passage">%s</a>' % [url, match]
        end
      end
      text
    end

    def random_book_and_chapter
      book = BOOKS_AND_CHAPTERS.keys.rand
      [book, BOOKS_AND_CHAPTERS[book].to_a.rand]
    end

  end

  # note: this must be called from a controller since this is habtm with people
  def create_as_stream_item(person, created_at=nil)
    StreamItem.create!(
      title:           reference,
      body:            text,
      person_id:       person.id,
      streamable_type: 'Verse',
      streamable_id:   id,
      created_at:      created_at || Time.now,
      shared:          person.share_activity?
    )
  end

  def delete_stream_items(person)
    StreamItem.destroy_all(streamable_type: 'Verse', streamable_id: id, person_id: person.id)
  end
end
