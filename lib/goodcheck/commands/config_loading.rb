module Goodcheck
  module Commands
    module ConfigLoading
      attr_reader :config

      def load_config!(force_download:, cache_path:)
        import_loader = ImportLoader.new(cache_path: cache_path, force_download: force_download, config_path: config_path)
        content = JSON.parse(JSON.dump(YAML.load(config_path.read, config_path.to_s)), symbolize_names: true)
        loader = ConfigLoader.new(path: config_path, content: content, stderr: stderr, import_loader: import_loader)
        @config = loader.load
      end
    end
  end
end
