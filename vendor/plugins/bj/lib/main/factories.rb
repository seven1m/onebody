module Main
  def Main.create *a, &b
    ::Main::Base.create(::Main::Base, *a, &b)
  end

  def Main.new *a, &b
    create(::Main::Base, &b).new *a
  end

  def Main.run argv = ARGV, env = ENV, opts = {}, &block
    Base.create(&block).new(argv, env, opts).run
  end

  module ::Kernel
    def Main argv = ARGV, env = ENV, opts = {}, &block
      ::Main.run argv, env, opts, &block
    end
    alias_method 'main', 'Main'
  end
end
