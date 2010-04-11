if RUBY_VERSION < '1.8.7'
  class Array
    def shift_with_count(count=nil)
      if count.nil?
        shift_without_count
      else
        shifted = []
        count.times { shifted << shift_without_count }
        shifted
      end
    end
    alias_method_chain :shift, :count
  end
end
