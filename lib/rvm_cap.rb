# Copyright (c) 2009-2011 Wayne E. Seguin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Recipes for using RVM on a server with capistrano.

unless Capistrano::Configuration.respond_to?(:instance)
  abort "rvm/capistrano requires Capistrano >= 2."
end

Capistrano::Configuration.instance(true).load do

  # Taken from the capistrano code.
  def _cset(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end

  set :default_shell do
    shell = File.join(rvm_bin_path, "rvm-shell")
    ruby = rvm_ruby_string.to_s.strip
    shell = "rvm_path=#{rvm_path} #{shell} '#{ruby}'" unless ruby.empty?
    shell
  end

  # Let users set the type of their rvm install.
  _cset(:rvm_type, :system)

  # Define rvm_path
  # This is used in the default_shell command to pass the required variable to rvm-shell, allowing
  # rvm to boostrap using the proper path.  This is being lost in Capistrano due to the lack of a
  # full environment.
  _cset(:rvm_path) do
    case rvm_type
    when :system_wide, :root, :system
      "/usr/local/rvm"
    when :local, :user, :default
      "$HOME/.rvm/"
    end
  end

  # Let users override the rvm_bin_path
  _cset(:rvm_bin_path) do
    case rvm_type
    when :system_wide, :root, :system
      "/usr/local/bin"
    when :local, :user, :default
      "$HOME/.rvm/bin"
    end
  end

  # Use the default ruby.
  _cset(:rvm_ruby_string, "default")

end

