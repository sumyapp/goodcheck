module Goodcheck
  module Pattern
    class Literal
      attr_reader :source
      attr_reader :case_sensitive

      def initialize(source:, case_sensitive:)
        @source = source
        @case_sensitive = case_sensitive
      end

      def regexp
        @regexp ||= ::Regexp.compile(::Regexp.escape(source), !case_sensitive)
      end
    end

    class Regexp
      attr_reader :source
      attr_reader :case_sensitive
      attr_reader :multiline

      def initialize(source:, case_sensitive:, multiline:)
        @source = source
        @case_sensitive = case_sensitive
        @multiline = multiline
      end

      def regexp
        @regexp ||= begin
          options = 0
          options |= ::Regexp::IGNORECASE unless case_sensitive
          options |= ::Regexp::MULTILINE if multiline
          ::Regexp.compile(source, options)
        end
      end
    end

    class Token
      attr_reader :source, :case_sensitive

      def initialize(source:, case_sensitive:)
        @case_sensitive = case_sensitive
        @source = source
      end

      def regexp
        @regexp ||= Token.compile_tokens(source, case_sensitive: case_sensitive)
      end

      def self.compile_tokens(source, case_sensitive:)
        tokens = []
        s = StringScanner.new(source)

        until s.eos?
          case
          when s.scan(/\(|\)|\{|\}|\[|\]|\<|\>/)
            tokens << ::Regexp.escape(s.matched)
          when s.scan(/\s+/)
            tokens << '\s+'
          when s.scan(/\w+|[\p{Letter}&&\p{^ASCII}]+/)
            tokens << ::Regexp.escape(s.matched)
          when s.scan(%r{[!"#$%&'=\-^~¥\\|`@*:+;/?.,]+})
            tokens << ::Regexp.escape(s.matched.rstrip)
          when s.scan(/./)
            tokens << ::Regexp.escape(s.matched)
          end
        end

        if tokens.first =~ /\A\p{Letter}/
          tokens.first.prepend('\b')
        end

        if tokens.last =~ /\p{Letter}\Z/
          tokens.last << '\b'
        end

        options = ::Regexp::MULTILINE
        options |= ::Regexp::IGNORECASE unless case_sensitive

        ::Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), options)
      end
    end
  end
end
