class OSwitch
  # Get OS specific info. Like, what directories to mount in the container,
  # current user, home directory, etc.
  #
  # This module first defines methods common to Linux and Darwin, then does
  # OS detection and loads OS specific code.
  module OS
    # Return `true` if the given command exists and is executable.
    def self.command?(command)
      system("which #{command} > /dev/null 2>&1")
    end

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

    # Detect Linux or Darwin and load OS specific code. Following
    # methods are added:
    #
    #   uid, gid, mountpoints
    #
    # NOTE:
    # This won't work on JRuby as it sets RUBY_PLATFORM to 'java'.
    case RUBY_PLATFORM
    when /linux/
      require_relative 'os/linux'
      include Linux
    when /darwin/
      require_relative 'os/darwin'
      include Darwin
    end
  end
end
