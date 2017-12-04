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

    def self.token(tokens)
      new(source: tokens, regexp: compile_tokens(tokens))
    end

    def self.compile_tokens(source)
      tokens = []
      s = StringScanner.new(source)

      until s.eos?
        case
        when s.scan(/\(|\)|\{|\}|\[|\]|\<|\>/)
          tokens << Regexp.escape(s.matched)
        when s.scan(/\s+/)
          tokens << '\s+'
        when s.scan(/(\p{Letter}|\w)+/)
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

      Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), Regexp::MULTILINE)
    end
  end
end
