unless String.instance_methods.include?(:any?)
  class String
    def any?; !empty?; end
  end
end
