# ---------------------------------------------------------------------------
# A simple copy script for doing hard links and symbolic links instead of
# explicit copies. Some OS's will already have a utility to do this, but
# some won't; this file suffices in either case.
#
# Usage: ruby copy.rb <source> <target> <exclude> ...
#
# The <source> directory is recursively descended, and hard links to all of
# the files are created in corresponding locations under <target>. Symbolic
# links in <source> map to symbolic links in <target> that point to the same
# destination.
#
# All arguments after <target> are taken to be exclude patterns. Any file
# or directory in <source> that matches any of those patterns will be
# skipped, and will thus not be present in <target>.
# ---------------------------------------------------------------------------
# This file is distributed under the terms of the MIT license by 37signals,
# LLC, and is copyright (c) 2008 by the same. See the LICENSE file distributed
# with this file for the complete text of the license.
# ---------------------------------------------------------------------------
require 'fileutils'

from = ARGV.shift or abort "need source directory"
to   = ARGV.shift or abort "need target directory"

exclude = ARGV

from = File.expand_path(from)
to   = File.expand_path(to)

Dir.chdir(from) do
  FileUtils.mkdir_p(to)
  queue = Dir.glob("*", File::FNM_DOTMATCH)
  while queue.any?
    item = queue.shift
    name = File.basename(item)

    next if name == "." || name == ".."
    next if exclude.any? { |pattern| File.fnmatch(pattern, item) }

    source = File.join(from, item)
    target = File.join(to, item)

    if File.symlink?(item)
      FileUtils.ln_s(File.readlink(source), target)
    elsif File.directory?(item)
      queue += Dir.glob("#{item}/*", File::FNM_DOTMATCH)
      FileUtils.mkdir_p(target, :mode => File.stat(item).mode)
    else
      FileUtils.ln(source, target)
    end
  end
end
