module MusicHelper
  def quote(text)
    text.gsub /'/, "\\'"
  end
end
