module Goodcheck
  module HomePath
    def cache_dir_path
      @cache_dir_path ||= (home_path + "cache").tap do |path|
        path.mkpath unless path.directory?
      end
    end
  end
end
