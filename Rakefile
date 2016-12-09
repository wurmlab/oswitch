GEMSPEC = eval File.read 'oswitch.gemspec'
PLATFORMS = %w|linux-x86 linux-x86_64 osx|
TRAVELING_RUBY_VERSION = '20150715-2.2.2'

PLATFORMS.each do |platform|
  file "traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz" do
    sh "wget -N " +
        "http://d6r77u77i8pq3.cloudfront.net" +
        "/releases/traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz"
  end
end

desc "Create standalone SequenceServer packages"
task :package do
  cd '..' do
    task('package:build' => ['package:linux-x86', 'package:linux-x86_64', 'package:osx']).invoke
  end
end

namespace :package do
  PLATFORMS.each do |platform|
    task platform => "traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz" do
      package_dir = "#{GEMSPEC.name}-#{GEMSPEC.version}-#{platform}"

      rm_rf package_dir
      mkdir package_dir

      cp_r "#{Rake.original_dir}/.", package_dir

      cd package_dir do
        mkdir 'vendor'
        sh "tar xzf ../traveling-ruby-#{TRAVELING_RUBY_VERSION}-#{platform}.tar.gz -C vendor"
        sh "chruby-exec 2.2.2 -- bundle install --deployment"
        File.write(GEMSPEC.name, <<SCRIPT)
#!/bin/bash
set -e

SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

export BUNDLE_GEMFILE="$SELFDIR/Gemfile"

exec "$SELFDIR/vendor/bin/ruby" -rbundler/setup "$SELFDIR/bin/#{GEMSPEC.name}" "$@"
SCRIPT
        sh "chmod +x #{GEMSPEC.name}"
      end

      if !ENV['DIR_ONLY']
        sh "tar czf #{package_dir}.tar.gz #{package_dir}"
        rm_rf package_dir
      end
    end
  end
end
