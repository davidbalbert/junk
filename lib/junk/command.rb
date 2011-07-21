require 'fileutils'
require 'pathname'
require 'trollop'

module Junk
  class Command

    SUB_COMMANDS = %w(init track help)

    HELP_STRING = <<-EOS
usage: junk [-v|--version] [--home] [-h|--help] COMMAND [ARGS]

Commands:
   init     Initialize a new junk drawer for the current directory
   track    Moves a file to your junk drawer and symlinks it from it's old location
   help     Displays information about a command
EOS

    attr_reader :args
    def initialize(*args)
      @args = args
      self.destination_root = Dir.pwd
    end

    def self.run(*args)
      new(*args).run
    end

    def run
      parser = Trollop::Parser.new do
        version "Junk #{Junk::VERSION}"
        banner "#{HELP_STRING}\nOptions:"
        opt :home, "Prints junk's home directory", :short => :none
        stop_on SUB_COMMANDS
      end

      @global_opts = Trollop::with_standard_exception_handling parser do
        o = parser.parse @args
        raise Trollop::HelpNeeded if ARGV.empty?
        o
      end

      if @global_opts[:home]
        puts junk_home
        exit(0)
      end

      cmd = @args.shift
      @cmd_opts = case cmd
        when "init", "track", "help"
        else
          error "unknown command '#{cmd}'."
        end

      self.send(cmd)
    end

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

    def track
      file = @args.shift

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

    def help
      puts HELP_STRING if @args.empty?
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
          return true
        end
      end

      false
    end

    def setup
      say "Setting up your junk home in #{junk_home}..."
      Dir.mkdir junk_home unless File.exists? junk_home

      inside(junk_home) do
        print ">>> "
        system("git init")
      end

      say ""
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

    #################################################################
    # Taken from Thor
    # Copyright (c) 2008 Yehuda Katz
    #
    def inside(dir, &block)
      @destination_stack.push File.expand_path(dir, destination_root)

      FileUtils.cd(destination_root) { block.arity == 1 ? yield(destination_root) : yield }

      @destination_stack.pop
    end

    def destination_root
      @destination_stack.last
    end

    def destination_root=(root)
      @destination_stack ||= []
      @destination_stack[0] = File.expand_path(root || '')
    end
    #
    #################################################################

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
      $stderr.puts "Error: #{str}"
    end

    def debug(str)
      say "debug: #{str}" if @debug
    end

    def say(str)
      puts str
    end
  end
end
