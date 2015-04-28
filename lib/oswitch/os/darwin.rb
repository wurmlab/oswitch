class OSwitch
  module OS
    # OS X specific code.
    module Darwin
      BLACKLIST =
        %r{
        ^/$|
        ^/(bin|cores|dev|etc|home|Incompatible\ Software|
          installer\.failurerequests|lost\+found|net|
          Network|opt|private|sbin|System|Users|tmp|
          usr|var|Volumes$)
        }x

      def uid
        `boot2docker ssh id -u`.chomp
      end

      def gid
        `boot2docker ssh id -g`.chomp
      end

      def mountpoints
        volumes = Dir['/Volumes/*'].map {|v| File.symlink?(v) ? File.readlink(v) : v}
        volumes = volumes | Dir['/*']
        volumes.reject! { |mount| mount =~ BLACKLIST }
        volumes << home
      end
    end
  end
end
