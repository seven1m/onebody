class String
  def digits_only
    d = scan(/\d/)
    d.join if d.any?
  end
end
