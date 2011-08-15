class Dir
  class << self
    def exists? (path)
      File.directory?(path)
    end
    alias_method :exist?, :exists?
  end
end
