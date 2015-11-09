require 'timeout'
require 'colorize'
require 'fileutils'
require 'shellwords'

require 'oswitch/exceptions'
require 'oswitch/image'
require 'oswitch/pkg'
require 'oswitch/os'

# OSwitch leverages docker to provide access to complex Bioinformatics software
# (even Biolinux!) in just one command.
#
# Images are built on the user's system on demand and executed in a container.
# Containers are removed after execution.
#
# Volumes from host OS are mounted in the container just the same, including
# home directory. USER, HOME, SHELL, and PWD are preserved.
class OSwitch
  include OS, Timeout

  DOTDIR = File.expand_path('~/.oswitch')

  class << self
    # Invoke as `OSwitch.to` instead of `OSwitch.new`.
    alias_method :to, :new
    private :new

    def packages
      Dir["#{DOTDIR}/*"].map do |rep|
        pkgs = Dir["#{rep}/*"].select {|pkg| File.directory?(pkg)}
        pkgs = [rep] if pkgs.empty?
        pkgs
      end.
      flatten.
      map {|pkg|
        pkg.gsub("#{DOTDIR}/", '')
      }
    end
  end

  def initialize(package, command = [])
    @package = package
    @command = command
    @imgname = "oswitch_#{@package}"
    @cntname = "#{@package.gsub(%r{/|:}, '_')}-#{Process.pid}"
    exec
  end

  attr_reader :package, :command, :imgname, :cntname

  def exec
    ping and build and switch
  rescue ENODKR, ENOPKG => e
    puts e
    exit
  rescue => e
    puts <<MSG

Ouch! Looks like you have hit a bug. Please could you report the below to our
issue tracker (https://github.com/wurmlab/oswitch/issues):

#{e}\n#{e.backtrace.join("\n")}

MSG
    exit
  end

  private

  def switch
    cmdline = "docker run --name #{cntname} --hostname #{cntname} -it --rm" \
      " -w #{cwd} #{mountargs} #{imgname} "
    if command.empty?
      # Display motd and run interactive shell.
      cmdline << "\"echo #{motd}; #{shell} -i\""
    else
      cmdline << "\"#{command}\""
    end
    Kernel.exec cmdline
  end

  def build
    return true if Image.exists? imgname
    create_context_dir &&
      system("docker build -t #{imgname} #{context_dir}") || !remove_context_dir
  end

  # Ping docker daemon. Raise error if no response within 10s.
  def ping
    pong = timeout 5, ENODKR do
      system 'docker info > /dev/null 2>&1'
    end
    pong or raise ENODKR
  end

  ## Code to generate context dir that will be built into a docker image. ##

  # Create context dir.
  def create_context_dir
    FileUtils.mkdir_p context_dir
    FileUtils.cp_r(template_files, context_dir)
    write_dockerfile
  end

  # Remove context dir.
  def remove_context_dir
    FileUtils.rm_r(context_dir)
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
    data << "RUN /_switch #{userargs} 2>&1"
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
    File.join(PREFIX, 'share', 'oswitch', 'context')
  end

  # Template files.
  def template_files
    Dir[File.join(template_dir, '*')]
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
    str.shellescape
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
