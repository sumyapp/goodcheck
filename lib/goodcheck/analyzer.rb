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
        regexp = Regexp.union(*rule.patterns.map(&:regexp))

        unless rule.negated?
          issues = []

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
          unless regexp =~ buffer.content
            yield Issue.new(buffer: buffer, range: nil, rule: rule, text: text)
          end
        end
      else
        enum_for(:scan)
      end
    end
  end
end
