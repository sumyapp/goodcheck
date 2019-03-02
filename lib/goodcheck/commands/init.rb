module Goodcheck
  module Commands
    class Init
      CONFIG = <<-EOC
rules:
  - id: com.example.1
    pattern: Github
    message: Do you want to write GitHub?
    glob:
      - "**/*.rb"
      - "**/*.{yaml,yml}"
      - "public/**/*.html"
    fail:
      - Signup via Github
    pass:
      - Signup via GitHub

exclude:
  - node_modules
  - vendor
      EOC

      attr_reader :stdout
      attr_reader :stderr
      attr_reader :path
      attr_reader :force

      def initialize(stdout:, stderr:, path:, force:)
        @stdout = stdout
        @stderr = stderr
        @path = path
        @force = force
      end

      def run
        if path.file? && !force
          stderr.puts "#{path} already exists. Try --force option to overwrite the file."
          return 1
        end

        path.open("w") do |io|
          io.print(CONFIG)
        end

        stdout.puts "Wrote #{path}. ✍️"

        0
      end
    end
  end
end
