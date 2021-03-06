require 'fileutils'
require 'find'
require 'pathname'
require 'trollop'

module Junk
  class Command

    PROXY_COMMANDS = %w(add commit diff remote push pull log)
    SUB_COMMANDS = %w(init clone track link unlink help status) + PROXY_COMMANDS

    HELP_STRING = <<-EOS
usage: junk [-v|--version] [--home] [--drawer] [-h|--help] COMMAND [ARGS]

Commands:
   init     Initialize a new junk drawer for the current directory
   clone    Clones a git repo into ~/.junkd
   track    Moves a file to the junk drawer and symlinks it from it's old location
   link     Links in the junk drawer with the same name as the current directory
   unlink   Removes any symlinks pointing to the current junk drawer
   help     Displays information about a command

Proxy Commands (passed to git):
   status
#{PROXY_COMMANDS.inject("") { |str, c| str << "   #{c}\n" }}
EOS

    CMD_HELP_STRINGS = {
      "init" => "usage: junk init\n\nInitialize a new junk drawer for the current directory",
      "clone" => "usage: junk clone REMOTE\n\nClone REMOTE into ~/.junkd",
      "track" => "usage: junk track FILE\n\nMoves FILE to the junk drawer and symlinks it from it's old location",
      "link" => "usage: junk link\n\nCreates symlinks to to all the files in the junk drawer with the same name as the current directory",
      "unlink" => "usage: junk unlink\n\nRemoves any symlinks pointing to the current junk drawer",
      "status" => "usage: junk status\n\nRuns `git status` in the current junk drawer",
      "help" => "usage: junk help COMMAND\n\nShows usage information for COMMAND"
    }

    PROXY_COMMANDS.each do |c|
      CMD_HELP_STRINGS[c] = "usage: junk #{c} ARGUMENTS\n\nRuns `git #{c} ARGUMENTS` in the current junk drawer"
    end

    attr_reader :args
    def initialize(*args)
      @args = args
    end

    def self.run(*args)
      new(*args).run
    end

    def run
      parser = Trollop::Parser.new do
        version "Junk #{Junk::VERSION}"
        banner "#{HELP_STRING}\nOptions:"
        opt :home, "Prints junk's home directory", :short => :none
        opt :drawer, "Prints the junk drawer for the current directory", :short => :none
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

      if @global_opts[:drawer]
        puts junk_repo!
        exit(0)
      end

      check_for_git!

      cmd = @args.shift
      @cmd_opts = case cmd
        when *SUB_COMMANDS
        else
          error "unknown command '#{cmd}'."
          exit(1)
        end

      if PROXY_COMMANDS.include? cmd
        proxy_command(cmd)
      else
        self.send(cmd)
      end
    end

    def init
      setup unless prefix_is_setup?

      drawer_name = get_drawer_name(Dir.pwd)

      Dir.chdir(junk_home) do
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

      Dir.chdir(parent_with_junk_drawer!) do
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

    def link
      junk_drawer = junk_drawer_for_directory(Dir.pwd)

      unless File.directory? junk_drawer
        if File.exists? junk_home
          error "#{junk_drawer} doesn't exist. Are you in the root directory of your project?"
        else
          error "#{junk_drawer} doesn't exist. Have you cloned your junk repo yet?"
        end

        exit(1)
      end

      say "found junk drawer #{junk_drawer}"
      unless File.exists? ".junk"
        say "linking #{junk_drawer} => .junk"
        File.symlink(junk_drawer, ".junk")
      end

      junk_drawer_path = Pathname.new(junk_drawer)
      Find.find(junk_drawer) do |path|
        unless File.directory? path
          rel_path = Pathname.new(path).relative_path_from(junk_drawer_path).to_s
          unless File.exists? rel_path
            say "linking #{path} => #{rel_path}"
            File.symlink(path, rel_path)
          end
        end
      end
    end

    def unlink
      junk_repo = junk_repo! # junk_repo! uses Dir.chdir without a block. Will fix this later maybe
      Dir.chdir(parent_with_junk_drawer!) do |dir|
        Find.find(Dir.pwd) do |path|
          if File.directory? path
            if File.basename(path)[0] == ?.
              Find.prune
            end
          elsif File.symlink? path
            if File.readlink(path).start_with? junk_repo
              puts "unlinking #{path}"
              File.unlink(path)
            end
          end
        end

        if File.exists? ".junk"
          puts "unlinking #{dir}/.junk"
          File.unlink(".junk")
        end
      end
    end

    def clone
      Dir.chdir(ENV["HOME"]) do
        exec_git_or_hub("clone #{@args.join(" ")} .junkd")
      end
    end

    def status
      Dir.chdir(junk_repo!) do
        exec_git_or_hub("status .")
      end
    end

    def proxy_command(cmd)
      Dir.chdir(junk_repo!) do
        exec_git_or_hub("#{cmd} #{@args.join(" ")}")
      end
    end

    def help
      if @args.empty?
        puts HELP_STRING
        return
      end

      cmd = @args.shift

      if CMD_HELP_STRINGS[cmd]
        puts CMD_HELP_STRINGS[cmd]
      else
        error "unknown command '#{cmd}'."
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
          return true
        end
      end

      false
    end

    def setup
      say "Setting up your junk home in #{junk_home}..."
      Dir.mkdir junk_home unless File.exists? junk_home

      Dir.chdir(junk_home) do
        print ">>> "
        system("git init")
      end

      say ""
    end

    def parent_with_junk_drawer!
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
        File.open(".gitignore", "r+") do |f|
          f.each do |l|
            return if l.chomp == path
          end
          f.puts(path)
        end
      end
    end

    def exec_git_or_hub(cmd)
      if has_hub?
        exec("hub #{cmd}")
      else
        exec("git #{cmd}")
      end
    end

    def has_hub?
      @has_hub ||= (`which hub` != "")
    end

    def junk_home
      @junk_home ||= File.join(ENV["HOME"], ".junkd")
    end

    def get_drawer_name(dir)
      File.basename(dir)
    end

    def junk_repo!
      junk_drawer_for_directory(parent_with_junk_drawer!)
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
