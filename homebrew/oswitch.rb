# Reference
# ---------
# 1. https://github.com/Homebrew/homebrew/blob/master/Library/Contributions/example-formula.rb
# 2. https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Formula-Cookbook.md#formula-cookbook

class Oswitch < Formula

  homepage 'https://github.com/yeban/oswitch'

  url  'https://github.com/yeban/oswitch/archive/v0.2.6.tar.gz'
  sha1 '87d4c9680c40eab6a503d24b7b09e7b069be7c67'

  depends_on 'ruby'

  def install
    # Build gem and install to prefix.
    system "gem build oswitch.gemspec && \
gem install -i #{prefix} oswitch-#{version}.gem"

    # Re-write RubyGem generated bin stub to load oswitch from prefix.
    inreplace "#{bin}/oswitch" do |s|
      s.gsub!(/require 'rubygems'/,
              "ENV['GEM_HOME']='#{prefix}'\nrequire 'rubygems'")
    end
  end
end
