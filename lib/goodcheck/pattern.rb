module Goodcheck
  class Pattern
    attr_reader :source
    attr_reader :regexp

    def initialize(source:, regexp:)
      @source = source
      @regexp = regexp
    end

    def self.literal(literal, case_insensitive:)
      new(source: literal, regexp: Regexp.compile(Regexp.escape(literal), case_insensitive))
    end

    def self.regexp(regexp, case_insensitive:, multiline:)
      options = 0
      options |= Regexp::IGNORECASE if case_insensitive
      options |= Regexp::MULTILINE if multiline

      new(source: regexp, regexp: Regexp.compile(regexp, options))
    end

    def self.token(tokens, case_insensitive:)
      new(source: tokens, regexp: compile_tokens(tokens, case_insensitive: case_insensitive))
    end

    def self.compile_tokens(source, case_insensitive:)
      tokens = []
      s = StringScanner.new(source)

      until s.eos?
        case
        when s.scan(/\(|\)|\{|\}|\[|\]|\<|\>/)
          tokens << Regexp.escape(s.matched)
        when s.scan(/\s+/)
          tokens << '\s+'
        when s.scan(/\w+|[\p{Letter}&&\p{^ASCII}]+/)
          tokens << Regexp.escape(s.matched)
        when s.scan(%r{[!"#$%&'=\-^~¥\\|`@*:+;/?.,]+})
          tokens << Regexp.escape(s.matched.rstrip)
        when s.scan(/./)
          tokens << Regexp.escape(s.matched)
        end
      end

      if tokens.first =~ /\A\p{Letter}/
        tokens.first.prepend('\b')
      end

      if tokens.last =~ /\p{Letter}\Z/
        tokens.last << '\b'
      end

      options = Regexp::MULTILINE
      options |= Regexp::IGNORECASE if case_insensitive

      Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), options)
    end
  end
end
