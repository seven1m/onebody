module VersesHelper
  SMALL_VERSE_MAX_LENGTH = 200

  def small_verse?(verse)
    verse.text.length <= SMALL_VERSE_MAX_LENGTH
  end
end
