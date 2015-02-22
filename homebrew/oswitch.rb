# Caveats
# -------
# Since we do gem install, it doesn't get uninstalled on brew install.
#
# Reference
# ---------
# 1. https://github.com/Homebrew/homebrew/blob/master/Library/Contributions/example-formula.rb
# 2. https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md#formula-cookbook

class Oswitch < Formula

  homepage 'https://github.com/yeban/oswitch'

  url  'https://github.com/yeban/oswitch/archive/v0.2.3.tar.gz'
  sha1 '87d4c9680c40eab6a503d24b7b09e7b069be7c67'

  depends_on 'ruby'

  def install
    system "gem build oswitch.gemspec && gem install oswitch-#{version}.gem"
    rewrite_executable
  end

  def rewrite_executable
    lines = File.readlines(executable)
    index = lines.index "require 'rubygems'\n"
    lines.insert index, "ENV.delete 'GEM_PATH'\n\n"
    lines.insert index, "ENV.delete 'GEM_HOME'\n"
    File.write(executable, lines.join)
  end

  def executable
    '/usr/local/bin/oswitch'
  end
end
