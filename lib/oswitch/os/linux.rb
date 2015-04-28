class OSwitch
  module OS
    # Linux specific code.
    module Linux
      BLACKLIST =
        %r{
        ^/$|
        ^/(bin|boot|dev|etc|home|lib|lib64|lost\+found|opt|proc|
          run(?!/media)|sbin|srv|sys|tmp|usr|var|
          initrd.img|initrd.img.old|vmlinuz|vmlinuz.old)
        }x

      def uid
        Process.uid
      end

      def gid
        Process.gid
      end

      def mountpoints
        volumes = IO.readlines('/proc/mounts')
          .map { |line| line.split(/\s+/)[1] }
          .map { |path| unescape(path)       }
        volumes = volumes | Dir['/*']

        volumes.reject! do |path|
          (path =~ BLACKLIST) || !File.readable?(path)
        end

        volumes << home
      end

      private

      def unescape(mount)
        mount
          .gsub(/\\040/, " ")
          .gsub(/\\012/, "\n")
          .gsub(/\\134/, "\\")
          .gsub(/\\011/, "\t")
      end
    end
  end
end
