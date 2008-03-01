class Object
  def singleton_class object = self, &block
    sc =
      class << object
        self
      end
    block ? sc.module_eval(&block) : sc
  end

end

module SaneAbort
  def abort message = nil
    if message
      message = message.to_s
      message.singleton_class{ attribute 'abort' => true }
      STDERR.puts message
    end
    exit 1
  end
end

  def abort message = nil
    if message
      message = message.to_s
      message.singleton_class{ attribute 'abort' => true }
      STDERR.puts message
    end
    exit 1
  end
  def Process.abort message = nil
    if message
      message = message.to_s
      message.singleton_class{ attribute 'abort' => true }
      STDERR.puts message
    end
    exit 1
  end
