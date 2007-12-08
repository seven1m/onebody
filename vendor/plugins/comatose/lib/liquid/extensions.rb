class String
  def to_liquid
    self
  end
end

class Array 
  def to_liquid
    self
  end
end

class Hash 
  def to_liquid
    self
  end
end

class Numeric
  def to_liquid
    self
  end
end

class Time
  def to_liquid
    self
  end
end

class DateTime
  def to_liquid
    self
  end
end

class Date
  def to_liquid
    self
  end
end

def true.to_liquid
  self
end

def false.to_liquid
  self
end

def nil.to_liquid
  self
end