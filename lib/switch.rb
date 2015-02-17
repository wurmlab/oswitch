require 'timeout'
require 'colorize'
require 'fileutils'
require 'shellwords'

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

    def uid
      Process.uid
    end

    def gid
      Process.gid
    end

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

  # NOTE:
  #   This won't work on JRuby, as it sets RUBY_PLATFORM to 'java'.
  case RUBY_PLATFORM
  when /linux/
    include Linux
  when /darwin/
    include Darwin
  end

  DOTDIR = File.expand_path('~/.switch')

  class << self
    # Invoke as `Switch.to` instead of `Switch.new`.
    alias_method :to, :new
    private :new

    def packages
      Dir["#{DOTDIR}/*"].
        select {|entry| File.directory? entry}.
        map {|pkg|
          pkg.gsub("#{DOTDIR}/", '')
        }
    end
  end

  def initialize(package, command = [])
    @package = package.strip
    @command = command.join(' ')
    @imgname = "switch_#{@package}"
    @cntname = "#{@package.gsub(%r{/|:}, '_')}-#{Process.pid}"
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
    cmdline = "docker run --name #{cntname} --hostname #{cntname} -it --rm" \
      " -w #{cwd} #{mountargs} #{imgname} "
    if command.empty?
      # Display motd and run interactive shell.
      cmdline << "#{shell} -c \"echo #{motd}; #{shell} -i\""
    else
      cmdline << "#{shell} -c \"#{command}\""
    end
    Kernel.exec cmdline
  end

  def build
    return true if Image.exists? imgname
    write_context && system("docker build -t #{imgname} #{context_dir}")
  end

  # Ping docker daemon. Raise error if no response within 10s.
  def ping
    pong = timeout 5, ENODKR do
      system 'docker info > /dev/null 2>&1'
    end
    pong or raise ENODKR
  end

  ## Code to generate context dir that will be built into a docker image. ##

  # Write data to context dir.
  def write_context
    create_context_dir
    write_dockerfile
  end

  # Create context dir.
  def create_context_dir
    FileUtils.mkdir_p context_dir
    FileUtils.cp_r(template_files, context_dir)
  end

  # Write Dockerfile.
  def write_dockerfile
    dockerfile = File.join(context_dir, 'Dockerfile')
    File.write(dockerfile, dockerfile_data)
  end

  # Generate String that get written to Dockerfile.
  def dockerfile_data
    data = ["FROM #{package}"]
    data << 'COPY _switch /'
    data << 'COPY wheel /etc/sudoers.d/'
    data << "RUN /_switch #{userargs} 2>&1 | tee /tmp/switch.log"
    data << 'ENV LC_ALL en_US.UTF-8'
    data << "USER #{username}"
    data << "ENTRYPOINT [\"#{shell}\", \"-c\"]"
    data.join("\n")
  end

  # Location of context dir.
  def context_dir
    File.join(DOTDIR, package)
  end

  # Location of template dir.
  def template_dir
    File.expand_path('../context/', File.dirname(__FILE__))
  end

  # Template files.
  def template_files
    Dir[File.join(template_dir, '*')]
  end


  ## Data required to switchify a container. ##
  def username
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

  def motd
    str =<<MOTD
################################################################################
You are now running: #{package}, in container: #{cntname}.

Container is distinct from the shell your launched this container from. Changes
you make here will be lost unless it's made to one of the directories below:

 - #{mountpoints.join("\n - ")}

It's possible you may not be able to write to one or more directories above,
but it should be possible to read data from all. Home directory is often the
safest to write to.

Press Ctrl-D or type 'exit' to go back.
################################################################################
MOTD
    str.blue.shellescape
  end

  def mountargs
    mountpoints.map do |mountpoint|
      "-v '#{mountpoint}':'#{mountpoint}'"
    end.join(' ')
  end

  def userargs
    [uid, gid, username, home, shell].join(' ')
  end
end
