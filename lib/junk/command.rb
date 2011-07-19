require 'thor'
require 'fileutils'

module Junk
  class Command < Thor

    include Thor::Actions

    def initialize(*)
      super
      @debug = options["verbose"]
    end

    class_option "verbose",  :type => :boolean, :banner => "Enable debug output", :aliases => "-V"

    desc "version", "Prints junk's version information"
    def version
      puts "Junk #{Junk::VERSION}"
    end
    map %w(-v --version) => :version

    desc "print_junk_home", "Prints junk's home directory"
    def print_junk_home
      say junk_home
    end
    map "--home" => :print_junk_home

    desc "init", "Initialize a new junk drawer for the current directory"
    def init
      check_for_git!
      setup unless prefix_is_setup?

      inside(junk_home) do
        if File.exists?(File.join(junk_home, drawer_name))
          error "There is already a junk drawer called #{drawer_name}."
          exit(1)
        end

        Dir.mkdir drawer_name
        say "Alright, #{Dir.pwd} now has a junk drawer."
      end
    end

    desc "add FILE", "Moves FILE to your junk drawer and symlinks it from it's old location"
    def add(file)
      # TODO: Make this do something
      # deal with recursive directory creation if the path is deep
      # instead of recursively adding, could do gross filename substitution and keep it flat in the junk drawer
      #
      # TODO: also add appending to .gitignore if it exists
    end

    private
    def check_for_git!
      if `which git` == ""
        error "You need git installed in your path to use junk."
        exit(1)
      end
    end

    def prefix_is_setup?
      if File.directory? junk_home
        `git status`
        if $? == 0
          debug "junk_home is setup"
          return true
        end
      end

      debug "junk_home is not setup"
      false
    end

    def setup
      say "Setting up your junk home in #{junk_home}..."
      Dir.mkdir junk_home unless File.exists? junk_home

      inside(junk_home) do
        print ">>> "
        system("git init")
      end

      say
    end

    def junk_home
      @junk_home ||= File.join(ENV["HOME"], ".junk")
    end

    def drawer_name
      @drawer_name ||= File.basename(Dir.pwd)
    end

    def error(str)
      $stderr.puts "error: #{str}"
    end

    def debug(str)
      say "debug: #{str}" if @debug
    end
  end
end
