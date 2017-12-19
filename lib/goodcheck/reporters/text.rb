module Goodcheck
  module Reporters
    class Text
      attr_reader :stdout
      attr_reader :stderr

      def initialize(stdout:, stderr:)
        @stdout = stdout
        @stderr = stderr
      end

      def analysis
        yield
      end

      def file(path)
        yield
      end

      def rule(rule)
        yield
      end

      def issue(issue)
        line = issue.buffer.line(issue.location.start_line).chomp
        end_column = if issue.location.start_line == issue.location.end_line
                       issue.location.end_column
                     else
                       line.bytesize
                     end
        colored_line = line.byteslice(0, issue.location.start_column) + Rainbow(line.byteslice(issue.location.start_column, end_column - issue.location.start_column)).red + line.byteslice(end_column, line.bytesize - end_column)
        stdout.puts "#{issue.path}:#{issue.location.start_line}:#{colored_line}:\t#{issue.rule.message.lines.first.chomp}"
      end
    end
  end
end
