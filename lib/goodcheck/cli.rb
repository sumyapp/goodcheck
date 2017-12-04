require "optparse"

module Goodcheck
  class CLI
    attr_reader :stdout
    attr_reader :stderr

    def initialize(stdout:, stderr:)
      @stdout = stdout
      @stderr = stderr
    end

    def run(args)
      command = args.shift&.to_sym
      case command
      when :check
        check(args)
      when :init
        init(args)
      when :test
        test(args)
      else
        stdout.puts "Unknown command: #{command}"
        1
      end
    rescue => exn
      stderr.puts exn.inspect
      exn.backtrace.each do |bt|
        stderr.puts "  #{bt}"
      end
      1
    end

    def check(args)
      config_path = Pathname("goodcheck.yml")
      targets = []
      rules = []
      format = nil

      OptionParser.new("Usage: goodcheck check [options] dirs...") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
        opts.on("-R RULE", "--rule=RULE") do |rule|
          rules << rule
        end
        opts.on("--format=FORMAT") do |f|
          format = f
        end
      end.parse!(args)

      if args.empty?
        targets << Pathname(".")
      else
        targets.push *args.map {|arg| Pathname(arg) }
      end

      reporter = case format
                 when "text", nil
                   Reporters::Text.new(stdout: stdout, stderr: stderr)
                 when "json"
                   Reporters::JSON.new(stdout: stdout, stderr: stderr)
                 else
                   stderr.puts "Unknown format: #{format}"
                   return 1
                 end

      Commands::Check.new(reporter: reporter, config_path: config_path, rules: rules, targets: targets).run
    end

    def test(args)
      config_path = Pathname("goodcheck.yml")

      OptionParser.new("Usage: goodcheck test [options]") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
      end.parse!(args)

      Commands::Test.new(stdout: stdout, stderr: stderr, config_path: config_path).run
    end

    def init(args)
      config_path = Pathname("goodcheck.yml")
      force = false

      OptionParser.new("Usage: goodcheck init [options]") do |opts|
        opts.on("-c CONFIG", "--config=CONFIG") do |config|
          config_path = Pathname(config)
        end
        opts.on("--force") do
          force = true
        end
      end.parse!(args)

      Commands::Init.new(stdout: stdout, stderr: stderr, path: config_path, force: force).run
    end
  end
end
