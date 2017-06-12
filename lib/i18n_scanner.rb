class I18nScanner
  def scan
    dirs = ['app/views/**/*', 'app/controllers/**/*'].map { |p| Rails.root.join(p) }
    Dir[*dirs].each do |view|
      next if File.directory?(view)
      path = view[Rails.root.join('app/views').to_s.length + 1..-1]
      namespace = path.sub(/\..+$/, '').gsub(/\//, '.')
      content = File.read(view).split(/\n/).reject { |l| l =~ /#\s*notest\s*$/ }.join("\n")
      content.scan(/(?:^|\W)t\((.+?)\)/).each do |(args)|
        key = args.match(/['"](.+?)['"]/)[1]
        key = namespace + key if key.start_with?('.')
        scope = args.match(/scope: ['"](.+?)['"]/).try(:[], 1)
        args = [key]
        args << { scope: scope } if scope
        yield(view, args)
      end
    end
  end

  def keys
    [].tap do |all|
      scan do |_view, args|
        key = args.first
        if args.last.is_a?(Hash) && args.last.try(:[], :scope)
          key = "#{args.last[:scope]}.#{key}"
        end
        all << key
      end
    end
  end
end
