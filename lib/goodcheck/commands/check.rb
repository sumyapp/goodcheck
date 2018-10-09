module Goodcheck
  module Commands
    class Check
      attr_reader :config_path
      attr_reader :rules
      attr_reader :targets
      attr_reader :reporter
      attr_reader :stderr
      attr_reader :force_download
      attr_reader :home_path

      include ConfigLoading
      include HomePath

      def initialize(config_path:, rules:, targets:, reporter:, stderr:, home_path:, force_download:)
        @config_path = config_path
        @rules = rules
        @targets = targets
        @reporter = reporter
        @stderr = stderr
        @force_download = force_download
        @home_path = home_path
      end

      def run
        issue_reported = false

        reporter.analysis do
          load_config!(force_download: force_download, cache_path: cache_dir_path)
          each_check do |buffer, rule|
            reporter.rule(rule) do
              analyzer = Analyzer.new(rule: rule, buffer: buffer)
              analyzer.scan do |issue|
                issue_reported = true
                reporter.issue(issue)
              end
            end
          end
        end

        issue_reported ? 2 : 0
      rescue Psych::Exception => exn
        stderr.puts "Unexpected error happens while loading YAML file: #{exn.inspect}"
        exn.backtrace.each do |trace_loc|
          stderr.puts "  #{trace_loc}"
        end
        1
      rescue StrongJSON::Type::Error => exn
        stderr.puts "Invalid config at #{exn.path.map {|x| "[#{x}]" }.join}"
        1
      rescue Errno::ENOENT => exn
        stderr.puts "#{exn}"
        1
      end

      def each_check
        targets.each do |target|
          Goodcheck.logger.info "Checking target: #{target}"
          Goodcheck.logger.tagged target.to_s do
            each_file target, immediate: true do |path|
              Goodcheck.logger.debug "Checking file: #{path}"
              Goodcheck.logger.tagged path.to_s do
                reporter.file(path) do
                  buffers = {}

                  config.rules_for_path(path, rules_filter: rules) do |rule, glob|
                    Goodcheck.logger.debug "Checking rule: #{rule.id}"
                    begin
                      encoding = glob&.encoding || Encoding.default_external.name

                      if buffers[encoding]
                        buffer = buffers[encoding]
                      else
                        content = path.read(encoding: encoding).encode(Encoding.default_internal || Encoding::UTF_8)
                        buffer = Buffer.new(path: path, content: content)
                        buffers[encoding] = buffer
                      end

                      yield buffer, rule
                    rescue ArgumentError => exn
                      stderr.puts "#{path}: #{exn.inspect}"
                    end
                  end
                end
              end
            end
          end
        end
      end

      def is_dotfile?(path)
        /\A\.[^.]+/.match?(path.basename.to_s)
      end

      def each_file(path, immediate: false, &block)
        case
        when path.symlink?
          # noop
        when path.directory?
          if !is_dotfile?(path) || is_dotfile?(path) && immediate
            path.children.each do |child|
              each_file(child, &block)
            end
          end
        when path.file?
          if path == config_path || is_dotfile?(path)
            # Skip dotfiles/config file unless explicitly given by command line
            yield path if immediate
          else
            yield path
          end
        end
      end
    end
  end
end
