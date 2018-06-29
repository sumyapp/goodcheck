module Goodcheck
  module Commands
    module ConfigLoading
      attr_reader :config

      def load_config!
        content = JSON.parse(JSON.dump(YAML.load(config_path.read, config_path.to_s)), symbolize_names: true)
        loader = ConfigLoader.new(path: config_path, content: content, stderr: stderr)
        @config = loader.load
      end
    end
  end
end
