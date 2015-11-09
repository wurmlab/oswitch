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

      def mountpoints
        volumes = Dir['/Volumes/*'].map {|v| File.symlink?(v) ? File.readlink(v) : v}
        volumes = volumes | Dir['/*']
        volumes.reject! { |mount| mount =~ BLACKLIST }
        volumes << home
      end

      if OS.command?('docker-machine')
        def uid
          OS.outputof('docker-machine ssh default id -u')
        end

        def gid
          OS.outputof('docker-machine ssh default id -g')
        end
      else
        puts <<WARN
'boot2docker' has been deprecated in favour of 'docker-machine'. Please upgrade
via the Docker Toolbox (https://docker.com/toolbox).
WARN
        def uid
          OS.outputof('boot2docker ssh id -u')
        end

        def gid
          OS.outputof('boot2docker ssh id -g')
        end
      end
    end
  end
end
