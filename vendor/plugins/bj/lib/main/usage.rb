module Main
  class Usage < ::Array
    attribute 'chunkname'
    attribute 'upcase'
    attribute 'eos'

    def initialize opts={} 
      self.fields=[]
      self.chunkname = lambda{|chunkname| chunkname.to_s.strip.upcase}
      self.upcase = true 
      self.eos = "\n\n"
      if opts.has_key?(:upcase) or opts.has_key?('upcase')
        self.upcase = opts[:upcase] || opts['optcase']
      end
    end

    def clear
      super
    ensure
      fields.clear
    end

    def delete_at key
      self[key] = nil
    end
    alias_method 'delete', 'delete_at'

    def self.default_synopsis main
    # build up synopsis
      s = "#{ main.name }"

    # mode info
      if main.mode_name != 'main'
        s << " #{ main.fully_qualified_mode.join ' ' }"
      end

      unless main.modes.empty?
        modes = main.modes.keys.join('|')
        s << " (#{ modes })"
      end

    # argument info
      main.parameters.each do |p|
        if p.type == :argument
          if(p.required? and p.arity != -1)
            if p.arity > 0
              p.arity.times{ s << " #{ p.name }" }
            else
              (p.arity.abs - 1).times{ s << " #{ p.name }" }
              s << " #{ p.name }*"
            end
          else
            #s << " [#{ p.name }]"
            if p.arity > 0
              a = []
              p.arity.times{ a << "#{ p.name }" }
              s << " [#{ a.join ' ' }]"
            else
              a = []
              (p.arity.abs - 1).times{ a << "#{ p.name }" }
              a << "#{ p.name }*"
              s << " [#{ a.join ' ' }]"
            end
          end
        end
      end

    # keyword info
      main.parameters.each do |p|
        if p.type == :keyword
          if p.required?
            s << " #{ p.name }=#{ p.name }"
          else
            s << " [#{ p.name }=#{ p.name }]"
          end
        end
      end

    # option info
      n = 0
      main.parameters.each do |p|
        if p.type == :option
          if p.required?
            case p.argument
              when :required
                s << " --#{ p.name }=#{ p.name }"
              when :optional
                s << " --#{ p.name }=[#{ p.name }]"
              else
                s << " --#{ p.name }"
            end
          else
            n += 1
          end
        end
      end
      if n > 0
        s << " [options]+"
      end

    # help info
=begin
      if main.modes.size > 0
        modes = main.modes.keys.join('|')
        s << "\n#{ main.name } (#{ modes }) help"
      end
      if main.mode_name != 'main'
        s << "\n#{ main.name } #{ main.fully_qualified_mode.join ' ' } help"
      else
        s << "\n#{ main.name } help"
      end
=end

      s
    end

    def name_section
      if main.version?
        "#{ main.name } v#{ main.version }"
      else
        "#{ main.name }"
      end
    end

    def synopsis_section
      main.synopsis
    end

    def description_section
      main.description if main.description?
    end

    def parameters_section
      arguments = main.parameters.select{|p| p.type == :argument}
      keywords = main.parameters.select{|p| p.type == :keyword}
      options = main.parameters.select{|p| p.type == :option}
      environment = main.parameters.select{|p| p.type == :environment}

      help, nothelp = options.partition{|p| p.name == 'help'}
      options = nothelp + help

      parameters = arguments + keywords + options + environment

      s =
        parameters.map do |p|
          ps = ''
          ps << Util.columnize("#{ p.synopsis }", :indent => 2, :width => 78)
          #ps << Util.columnize("* #{ p.synopsis }", :indent => 2, :width => 78)
          #ps << "\n"
          if p.description?
            ps << "\n"
            ps << Util.columnize("#{ p.description }", :indent => 6, :width => 78)
            #ps << Util.columnize(p.description, :indent => 6, :width => 78)
            #ps << "\n"
          end
          #ps << "\n"
          unless(p.examples.nil? or p.examples.empty?)
            p.examples.each do |example|
              ps << "\n"
              ps << Util.columnize("#{ example }", :indent => 8, :width => 78)
            end
          end
          ps
        end.join("\n")
    end

    def author_section
      main.author
    end

    class << self
      def default_usage main
        usage = new
        usage.main = main
# HACK
        %w( name synopsis description parameters author ).each do |key|
          usage[key] = nil
        end
        usage
      end

      alias_method "default", "default_usage"
    end

    attribute "main"

    def set_defaults!
      usage = self
      usage['name']        ||= name_section
      usage['synopsis']    ||= synopsis_section
      usage['description'] ||= description_section
      usage['parameters']  ||= parameters_section unless main.parameters.empty?
      usage['author']      ||= author_section if main.author?
    end

    def to_s
      set_defaults!
      s = '' 
      each_pair do |key, value|
        next unless(key and value)
        up, down = key.to_s.upcase, key.to_s.downcase
        if value
          s << (upcase ? up : down) << "\n" 
          s << Util.indent(Util.unindent(value.to_s), 2)
          s << eos 
        end
      end
      s
    end
  end
end
