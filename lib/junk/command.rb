require 'thor'
require 'fileutils'
require 'pathname'

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

      drawer_name = get_drawer_name(Dir.pwd)

      inside(junk_home) do
        if File.exists?(File.join(junk_home, drawer_name))
          error "There is already a junk drawer called #{drawer_name}."
          exit(1)
        end

        Dir.mkdir drawer_name
      end

      File.symlink(File.join(junk_home, drawer_name), File.join(Dir.pwd, ".junk"))

      add_to_git_ignore(".junk")

      say "Alright, #{Dir.pwd} now has a junk drawer."
    end

    desc "track FILE", "Moves FILE to your junk drawer and symlinks it from it's old location"
    def track(file)
      inside(find_junk_drawer_symlink!) do
        unless File.exists? file
          error "#{file} doesn't seem to exist."
          exit(1)
        end

        if file[0] == '/'
          pwd = Pathname.new(Dir.pwd)
          file_path = Pathname.new(file)
          relative_path = file_path.relative_path_from(pwd).to_s
        else
          relative_path = file
        end

        if File.directory? relative_path
          error "junk doesn't support adding directories, only single files :(."
          exit(1)
        end

        dir, filename = File.split(relative_path)
        new_path = File.join(junk_drawer_for_directory(Dir.pwd), dir)
        unless File.exists? new_path
          FileUtils.mkpath(new_path)
        end

        new_path = File.join(junk_drawer_for_directory(Dir.pwd), relative_path)
        if File.exists? new_path
          error "it looks like you've already added #{file}"
          exit(1)
        end

        FileUtils.mv(relative_path, new_path)
        File.symlink(new_path, relative_path)

        add_to_git_ignore(relative_path)
      end
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

    def find_junk_drawer_symlink!
      old_pwd = Dir.pwd

      loop do
        if Dir.pwd == "/"
          Dir.chdir old_pwd
          error "it looks like this folder doesn't have a junk drawer"
          exit(1)
        elsif Dir.exists? ".junk"
          junk_dir = Dir.pwd
          Dir.chdir old_pwd
          return junk_dir
        end
        Dir.chdir ".."
      end
    end

    def add_to_git_ignore(path)
      if File.exists? ".gitignore"
        File.open(".gitignore", "a") { |f| f.puts(path) }
      end
    end

    def junk_home
      @junk_home ||= File.join(ENV["HOME"], ".junkd")
    end

    def get_drawer_name(dir)
      File.basename(dir)
    end

    def junk_drawer_for_directory(dir)
      File.join(junk_home, File.basename(dir))
    end

    def error(str)
      $stderr.puts "error: #{str}"
    end

    def debug(str)
      say "debug: #{str}" if @debug
    end
  end
end
