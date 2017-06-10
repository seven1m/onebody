# coding: utf-8

require 'net/http'

class Verse < ActiveRecord::Base
  has_and_belongs_to_many :people, -> { where('people.visible' => true) }
  has_many :comments, as: :commentable, dependent: :destroy
  belongs_to :site

  scope_by_site_id

  scope :with_people_count, -> { select('*, (select count(*) from people_verses where verse_id = verses.id) as people_count') }

  acts_as_taggable

  def admin?(person)
    people.include?(person) || person.admin?(:manage_verses)
  end

  def to_param
    reference
  end

  def name
    reference
  end

  def title
    reference
  end

  def body
    text
  end

  def book_name
    @book_name ||= reference.gsub(/[\d\:\s\-;,]+$/, '')
  end

  API_URL = 'http://bible-api.com/'.freeze

  def lookup
    return if reference.nil? || reference.empty?
    self.translation = 'WEB' if translation.nil?
    if (result = self.class.fetch(reference)) && result['error'].nil?
      self.reference = result['reference']
      self.text = result['text']
      update_sortables
    end
  end

  def lookup!
    lookup
    save
  end

  def update_sortables
    self.book = Verse::BOOKS.index(book_name)
    self.chapter = reference.gsub(/^.\s*[^\d]*/, '').to_i
    self.verse = reference.split(':').last.to_i
  end

  def <=>(v)
    [book, chapter, verse] <=> [v.book, v.chapter, v.verse]
  end

  validates_presence_of :text, :reference
  validates_length_of :text, maximum: 2500, allow_nil: true

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
    'Revelation'
  ].freeze

  def readable_by?(*_args)
    true # everyone can see bible verses!
  end

  class << self
    def find(reference_or_id, options = nil)
      if reference_or_id.nil?
        nil
      elsif reference_or_id.to_s =~ /^\d+$/
        super
      else
        find_by_reference(reference_or_id)
      end
    end

    def find_by_reference(reference)
      verse = where(reference: reference).first
      return verse if verse
      verse = where(reference: Verse.normalize_reference(reference) || reference).first_or_initialize
      verse.lookup!
      verse
    end

    def fetch(ref)
      url = "#{API_URL}#{URI.escape(ref)}?translation=#{Setting.get(:system, :bible_translation).presence || 'web'}"
      begin
        JSON.parse(Net::HTTP.get(URI.parse(url)))
      rescue JSON::ParserError, SocketError
        nil
      end
    end

    def normalize_reference(reference)
      if result = fetch(reference)
        result['reference']
      end
    end
  end

  # note: this must be called from a controller since this is habtm with people
  def create_as_stream_item(person, created_at = nil)
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
