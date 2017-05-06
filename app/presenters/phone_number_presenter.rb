class PhoneNumberPresenter
  def initialize(number, format)
    @number = number.to_s.strip
    @format = format
  end

  attr_reader :number, :format

  def formatted
    return '' if number.blank?
    digits = number.chars
    out = format.chars.map do |place|
      if place == 'd'
        digits.shift
      else
        place
      end
    end
    out += [' ', digits].flatten if digits.any?
    out.join
  end
end
