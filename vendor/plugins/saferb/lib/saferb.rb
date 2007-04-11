require 'active_record'

module ActiveRecord
  class Base
    alias_method :non_tainting_read_attribute, :read_attribute
    def read_attribute(name)
      v = non_tainting_read_attribute(name)
      v.taint if v.is_a? String
      return v
    end
  end
end

class ERB
  class Compiler
    def compile(s)
      out = Buffer.new(self)
      content = ''
      scanner = make_scanner(s)
      scanner.scan do |token|
        if scanner.stag.nil?
          case token
          when PercentLine
            out.push("#{@put_cmd} #{content.dump}") if content.size > 0
            content = ''
            out.push(token.to_s)
            out.cr
          when :cr
            out.cr
          when '<%', '<%=', '<%#'
            scanner.stag = token
            out.push("#{@put_cmd} #{content.dump}") if content.size > 0
            content = ''
          when "\n"
            content << "\n"
            out.push("#{@put_cmd} #{content.dump}")
            out.cr
            content = ''
          when '<%%'
            content << '<%'
          else
            content << token
          end
        else
          case token
          when '%>'
            case scanner.stag
            when '<%'
              if content[-1] == ?\n
                content.chop!
                out.push(content)
                out.cr
              else
                out.push(content)
              end
            when '<%='
              src = '<%=' + content.gsub(/"/, '\"') + '%>'
              out.push("if (c=(#{content}).to_s).tainted?; raise \"unescaped string detected in ERB line: #{src}\"; else; #{@put_cmd}(c); end")
            when '<%#'
              # out.push("# #{content.dump}")
            end
            scanner.stag = nil
            content = ''
          when '%%>'
            content << '%>'
          else
            content << token
          end
        end
      end
      out.push("#{@put_cmd} #{content.dump}") if content.size > 0
      out.close
      out.script
    end
  end
  
  module Util
    alias_method :non_tainting_html_escape, :html_escape
    def html_escape(s)
      s = non_tainting_html_escape(s)
      s.untaint
      return s
    end
    alias h html_escape
    module_function :h
    module_function :html_escape
    
    # use this sparingly, and definitely don't just
    # get in the habit of using to avoid those pesky error messages
    # (that kinda defeats the purpose)
    def untaint_string(s)
      s.untaint
      return s
    end
    alias u untaint_string
    module_function :u
    module_function :untaint_string
  end
end

module ActionView
  class Base
    include ERB::Util
  end
  module Helpers
    module TagHelper
      include ERB::Util
    end
    module FormOptionsHelper
      include ERB::Util
    end
  end
end