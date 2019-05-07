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

        regexp = Regexp.union(*rule.patterns.map(&:regexp))
        scanner = StringScanner.new(buffer.content)

        while true
          case
          when scanner.scan_until(regexp)
            text = scanner.matched
            range = (scanner.pos - text.bytesize) .. scanner.pos
            issues << Issue.new(buffer: buffer, range: range, rule: rule, text: text)
          else
            break
          end
        end

        issues.each(&block)
      else
        enum_for(:scan)
      end
    end
  end
end
