require 'ostruct'

class Search
  def initialize(params = {})
    params.each do |key, val|
      send("#{key}=", val) if respond_to?("#{key}=")
    end
    build_scope
  end

  def results
    execute
    @scope
  end

  def count
    execute
    @scope.count
  end

  def reset
    build_scope
    @executed = false
  end

  private

  def where(*args)
    @scope = @scope.where(*args)
  end

  def order(*args)
    @scope = @scope.order(*args)
  end

  def like
    if @scope.connection.adapter_name == 'PostgreSQL'
      'ilike'
    else
      'like'
    end
  end

  def like_match(str, position = :both)
    str.to_s.dup.gsub(/[%_]/) { |x| '\\' + x }.tap do |s|
      s.insert(0, '%') if [:before, :both].include?(position)
      s << '%'         if [:after,  :both].include?(position)
    end
  end
end
