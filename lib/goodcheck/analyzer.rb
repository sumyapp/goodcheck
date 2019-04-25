module Goodcheck
  class Analyzer
    attr_reader :rule
    attr_reader :buffer

    def initialize(rule:, buffer:)
      @rule = rule
      @buffer = buffer
    end

    def scan(&block)
      if block_given?
        issues = []

        rule.patterns.each do |pattern|
          scanner = StringScanner.new(buffer.content)

          while true
            case
            when scanner.scan_until(pattern.regexp)
              text = scanner.matched
              range = (scanner.pos - text.bytesize) .. scanner.pos
              unless issues.any? {|issue| issue.range == range }
                issues << Issue.new(buffer: buffer, range: range, rule: rule, text: text)
              end
            else
              break
            end
          end
        end

        issues.each(&block)
      else
        enum_for(:scan, &block)
      end
    end
  end
end
