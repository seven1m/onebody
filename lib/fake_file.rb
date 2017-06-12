class FakeFile < StringIO
  def initialize(data, filename)
    super(data)
    @filename = filename
  end

  def original_filename
    @filename
  end

  def path
    @filename
  end

  def size
    length
  end
end
