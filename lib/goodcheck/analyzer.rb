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
          var_pats, novar_pats = trigger.patterns.partition {|pat|
            pat.is_a?(Pattern::Token) && !pat.variables.empty?
          }

          unless var_pats.empty?
            var_pats.each do |pat|
              scan_var pat, &block
            end
          end

          unless novar_pats.empty?
            regexp = Regexp.union(*novar_pats.map(&:regexp))
            scan_simple regexp, &block
          end
        end
      else
        enum_for(:scan)
      end
    end

    def scan_simple(regexp, &block)
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

    def scan_var(pat)
      scanner = StringScanner.new(buffer.content)

      unless trigger.negated?
        while true
          case
          when scanner.scan_until(pat.regexp)
            if pat.test_variables(scanner)
              text = scanner.matched
              range = (scanner.pos - text.bytesize) .. scanner.pos
              yield Issue.new(buffer: buffer, range: range, rule: rule, text: text)
            end
          else
            break
          end
        end
      else
        while true
          case
          when scanner.scan_until(pat.regexp)
            if pat.test(scanner)
              break
            end
          else
            yield Issue.new(buffer: buffer, range: nil, rule: rule, text: nil)
            break
          end
        end
      end
    end
  end
end
