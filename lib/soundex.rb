class String
  def soundex
    copy = self.upcase.tr '^A-Z', ''
    return nil if copy.empty?
    first_letter = copy[0, 1]
    copy.tr_s! 'AEHIOUWYBFPVCGJKQSXZDTLMNR', '00000000111122222222334556'
    copy.sub!(/^(.)\1*/, '').gsub!(/0/, '')
    "#{first_letter}#{copy.ljust(3,"0")}"
  end
end
