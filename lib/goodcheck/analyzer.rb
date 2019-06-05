module Goodcheck
  class Analyzer
    attr_reader :rule
    attr_reader :trigger
    attr_reader :buffer

    def initialize(rule:, trigger:, buffer:)
      @rule = rule
      @trigger = trigger
      @buffer = buffer
    end

    def scan(&block)
      if block_given?
        if trigger.patterns.empty?
          yield Issue.new(buffer: buffer, range: nil, rule: rule, text: nil)
        else
          regexp = Regexp.union(*trigger.patterns.map(&:regexp))

          unless trigger.negated?
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
              yield Issue.new(buffer: buffer, range: nil, rule: rule, text: nil)
            end
          end
        end
      else
        enum_for(:scan)
      end
    end
  end
end
