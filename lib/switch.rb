require 'timeout'

# Switch leverages docker to provide access to complex Bioinformatics software
# (even Biolinux!) in just one command.
#
# Images are built on the user's system on demand and executed in a container.
# Containers are removed after execution.
#
# Volumes from host OS are mounted in the container just the same, including
# home directory. USER, HOME, SHELL, and PWD are preserved.
class Switch

  class ENOPKG < StandardError

    def initialize(name)
      @name = name
    end

    def to_s
      "Recipe to run #@name not available."
    end
  end

  class ENODKR < StandardError

    def to_s
      "***** Docker not installed / correctly setup / running.
      Are you able to run 'docker info'?"
    end
  end

  include Timeout

  # Captures a docker image's metadata.
  Image = Struct.new :repository, :tag, :id, :created, :size

  class Image

    # Model Image's eigenclass as a collection of Image objects.
    class << self

      include Enumerable

      def all
        `docker images`.split("\n").drop(1).
          map{|l| Image.new(*l.split(/\s{2,}/))}
      end

      def each(&block)
        all.each(&block)
      end

      def get(imgname)
        repository, tag = imgname.split(':')
        return if not repository or repository.empty?
        tag = 'latest' if not tag or tag.empty?
        find {|img| img.repository == repository and img.tag == tag}
      end

      def exists?(imgname)
        !!get(imgname)
      end
    end
  end

  # Linux specific code.
  module Linux

    # Parse /proc/mounts for mountpoints.
    def mountpoints
      mtab = IO.readlines '/proc/mounts'
      mountpoints = mtab.map{ |line| line.split(/\s+/)[1]}
      mountpoints.map!{ |mount| unescape(mount) }
      # Ignore common system mountpoints.
      mountpoints.reject!{ |mount| mount =~ /^\/$/ }
      mountpoints.reject!{ |mount| mount =~ /^\/(proc|sys|usr|boot|tmp|dev|var|bin|etc|lib).*/ }
      # Mount /run/media/* but ignore other /run/ mountpoints.
      mountpoints.reject!{ |mount| mount =~ /^\/run.*/ unless mount =~ /^\/run\/(media.*)/ }

      # Add home dir.
      mountpoints << home
    end

    private

    def unescape(mount)
      mount.gsub(/\\040/, " ").gsub(/\\012/, "\n").gsub(/\\134/, "\\").gsub(/\\011/, "\t")
    end
  end

  # Mac OS X specific code.
  module Darwin

    BLACKLIST =
      %r{
    (^/$)|
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
  end

  # NOTE:
  #   This won't work on JRuby, as it sets RUBY_PLATFORM to 'java'.
  case RUBY_PLATFORM
  when /linux/
    include Linux
  when /darwin/
    include Darwin
  end

  class << self
    # Invoke as `Switch.to` instead of `Switch.new`.
    alias_method :to, :new
    private :new

    def packages
      pkgsdir = File.expand_path("../Dockerfiles", File.dirname(__FILE__))
      Dir["#{pkgsdir}/*"].
        select {|entry| File.directory? entry}.
        map {|entry|
          Dir["#{entry}/*"].
            select {|e| File.directory? e}
        }.
        flatten.
        map {|pkg|
          pkg.gsub("#{pkgsdir}/", '').gsub!('/', '_')
        }
    end
  end

  def initialize(package, command = [])
    @package = package.strip
    @command = command.join(' ')

    # If user already has biolinux image on his system, we don't want to be
    # using that, because we can't ensure the same reproducibile setup then.
    # Let's prefix our images with 'switch/' to keep them separate from other
    # images on the user's system. It must be noted though that other program
    # may use the same prefix, and thus our images aren't truly isolated.
    @imgname = "switch/#{@package.gsub('_', ':')}"

    @cntname = "#@package-#{Process.pid}"

    exec
  end

  attr_reader :package, :command, :imgname, :cntname

  def exec
    ping and build and switch
  rescue ENODKR, ENOPKG => e
    puts e
    exit
  end

  private

  def switch
    cmdline = "docker run --name #{cntname} --hostname #{cntname} -it --rm=true" \
      " #{mountargs} #{imgname} #{userargs} #{command}"
    Kernel.exec cmdline
  end

  def build
    raise ENOPKG, package unless srcpath
    return true if Image.exists? imgname
    build_baseimage and system "docker build -t #{imgname} #{srcpath}"
  end

  # Ping docker daemon. Raise error if no response within 10s.
  def ping
    timeout(5, ENODKR) { system 'docker info &> /dev/null' } or raise ENODKR
  end

  def srcpath
    path = File.expand_path("../Dockerfiles/#{package.gsub('_', '/')}",
                            File.dirname(__FILE__))
    return path if File.directory? path
  end

  def build_baseimage
    path = File.expand_path("../Dockerfiles/baseimage", File.dirname(__FILE__))
    name = 'switch/baseimage'
    return true if Image.exists? name
    system "docker build -t #{name} #{path}"
  end

  def user
    ENV['USER']
  end

  def home
    ENV['HOME']
  end

  def shell
    File.basename ENV['SHELL']
  end

  def cwd
    Dir.pwd
  end

  def mountargs
    mountpoints.map do |mountpoint|
      "-v '#{mountpoint}':'#{mountpoint}'"
    end.join(' ')
  end

  def userargs
    [user, home, shell, cwd].join(' ')
  end
end
