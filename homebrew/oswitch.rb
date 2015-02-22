# Caveats
# -------
# If you are using chruby, the installed oswitch binary works only after
# `chruby system`.
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
  end
end
