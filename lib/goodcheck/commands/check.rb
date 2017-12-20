module Goodcheck
  module Commands
    class Check
      attr_reader :config_path
      attr_reader :rules
      attr_reader :targets
      attr_reader :reporter

      include ConfigLoading

      def initialize(config_path:, rules:, targets:, reporter:)
        @config_path = config_path
        @rules = rules
        @targets = targets
        @reporter = reporter
      end

      def run
        reporter.analysis do
          load_config!
          each_check do |buffer, rule|
            reporter.rule(rule) do
              analyzer = Analyzer.new(rule: rule, buffer: buffer)
              analyzer.scan do |issue|
                reporter.issue(issue)
              end
            end
          end
        end
        0
      rescue Psych::Exception => exn
        reporter.stderr.puts "Unexpected error happens while loading YAML file: #{exn.inspect}"
        exn.backtrace.each do |trace_loc|
          reporter.stderr.puts "  #{trace_loc}"
        end
        1
      rescue StrongJSON::Type::Error => exn
        reporter.stderr.puts "Invalid config at #{exn.path.map {|x| "[#{x}]" }.join}"
        1
      rescue Errno::ENOENT => exn
        reporter.stderr.puts "#{exn}"
        1
      end

      def each_check
        targets.each do |target|
          each_file target do |path|
            reporter.file(path) do
              buffers = {}

              config.rules_for_path(path, rules_filter: rules) do |rule, glob|
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
                  reporter.error(path, exn)
                end
              end
            end
          end
        end
      end

      def each_file(path, &block)
        realpath = path.realpath

        case
        when realpath.directory?
          path.children.each do |child|
            each_file(child, &block)
          end
        when realpath.file?
          yield path
        end
      end
    end
  end
end
