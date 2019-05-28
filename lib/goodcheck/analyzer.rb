module Goodcheck
  class Analyzer
    attr_reader :rule
    attr_reader :buffer

    def initialize(rule:, buffer:)
      @rule = rule
      @buffer = buffer
    end

    def use_all_patterns!
      @use_all_patterns = true
    end

    def patterns
      if @use_all_patterns
        rule.patterns
      else
        rule.patterns.select do |pattern|
          case
          when pattern.globs.empty? && rule.globs.empty?
            true
          when pattern.globs.empty?
            rule.globs.any? {|glob| glob.test(buffer.path) }
          else
            pattern.globs.any? {|glob| glob.test(buffer.path) }
          end
        end
      end
    end

    def scan(&block)
      if block_given?
        if rule.patterns.empty?
          yield Issue.new(buffer: buffer, range: nil, rule: rule, text: nil)
        else
          regexp = Regexp.union(*patterns.map(&:regexp))

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
