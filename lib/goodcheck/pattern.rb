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

      def initialize(source:, case_sensitive:, multiline:, regexp: nil)
        @source = source
        @case_sensitive = case_sensitive
        @multiline = multiline
        @regexp = regexp
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
      attr_reader :source, :case_sensitive, :variables

      def initialize(source:, variables:, case_sensitive:)
        @source = source
        @variables = variables
        @case_sensitive = case_sensitive
      end

      def regexp
        @regexp ||= Token.compile_tokens(source, variables, case_sensitive: case_sensitive)
      end

      class VarPattern
        attr_reader :negated
        attr_reader :patterns
        attr_accessor :type

        def initialize(patterns:, negated:)
          @patterns = patterns
          @negated = negated
        end

        def cast(str)
          case type
          when :int
            str.to_i
          when :float, :number
            str.to_f
          else
            str
          end
        end

        def test(str)
          return true if patterns.empty?

          value = cast(str)

          unless negated
            patterns.any? {|pattern| pattern === value }
          else
            patterns.none? {|pattern| pattern === value }
          end
        end

        def self.empty
          VarPattern.new(patterns: [], negated: false)
        end
      end

      def test_variables(match)
        variables.all? do |name, var|
          str = match[name]
          str && var.test(str)
        end
      end

      @@TYPES = {}

      @@TYPES[:string] = -> (name) {
        ::Regexp.union(
          /"(?<#{name}>(?:[^"]|\")*)"/,
          /'(?<#{name}>(?:[^']|\')*)'/
        )
      }

      @@TYPES[:number] = -> (name) {
        ::Regexp.union(
          regexp_for_type(name: name, type: :int),
          regexp_for_type(name: name, type: :float)
        )
      }

      @@TYPES[:int] = -> (name) {
        ::Regexp.union(
          /(?<#{name}>[+-]?[1-9](:?\d|_\d)*)/,
          /(?<#{name}>[+-]?0[dD][0-7]+)/,
          /(?<#{name}>[+-]?0[oO]?[0-7]+)/,
          /(?<#{name}>[+-]?0[xX][0-9a-fA-F]+)/,
          /(?<#{name}>[+-]?0[bB][01]+)/
        )
      }

      @@TYPES[:float] = -> (name) {
        ::Regexp.union(
          /(?<#{name}>[+-]?\d+\.\d*(:?e[+-]?\d+)?)/,
          /(?<#{name}>[+-]?\d+(:?e[+-]?\d+)?)/
        )
      }

      @@TYPES[:word] = -> (name) {
        /(?<#{name}>\S+)/
      }

      @@TYPES[:identifier] = -> (name) {
        /(?<#{name}>[a-zA-Z_]\w*)\b/
      }

      # From rails_autolink gem
      # https://github.com/tenderlove/rails_autolink/blob/master/lib/rails_autolink/helpers.rb#L73
      # With ')' support, which should be frequently used for markdown or CSS `url(...)`
      AUTO_LINK_RE = %r{
        (?: ((?:ed2k|ftp|http|https|irc|mailto|news|gopher|nntp|telnet|webcal|xmpp|callto|feed|svn|urn|aim|rsync|tag|ssh|sftp|rtsp|afs|file):)// | www\. )
        [^\s<\u00A0")]+
      }ix

      # https://github.com/tenderlove/rails_autolink/blob/master/lib/rails_autolink/helpers.rb#L81-L82
      AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&'*\/=?^`{|}~+-]/
      AUTO_EMAIL_RE = /(?<!#{AUTO_EMAIL_LOCAL_RE})[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+/

      @@TYPES[:url] = -> (name) {
        /\b(?<#{name}>#{AUTO_LINK_RE})/
      }

      @@TYPES[:email] = -> (name) {
        /\b(?<#{name}>#{AUTO_EMAIL_RE})/
      }

      def self.regexp_for_type(name:, type:)
        ty = type || :word
        if @@TYPES.key?(ty)
          @@TYPES[ty][name]
        end
      end

      def self.compile_tokens(source, variables, case_sensitive:)
        tokens = []
        s = StringScanner.new(source)

        until s.eos?
          case
          when s.scan(/\${(?<name>[a-zA-Z_]\w*)(?::(?<type>#{::Regexp.union(*@@TYPES.keys.map(&:to_s))}))?}/)
            name = s[:name].to_sym
            type = s[:type] && s[:type].to_sym

            if variables.key?(name)
              variables[name].type = type
              regexp = regexp_for_type(name: name, type: type).to_s
              if tokens.empty? && (type == :word || type == :identifier)
                regexp = /\b#{regexp.to_s}/
              end
              tokens << regexp.to_s
            else
              tokens << ::Regexp.escape("${")
              tokens << ::Regexp.escape(name.to_s)
              tokens << ::Regexp.escape("}")
            end
          when s.scan(/\(|\)|\{|\}|\[|\]|\<|\>/)
            tokens << ::Regexp.escape(s.matched)
          when s.scan(/\s+/)
            tokens << '\s+'
          when s.scan(/\w+|[\p{L}&&\p{^ASCII}]+/)
            tokens << ::Regexp.escape(s.matched)
          when s.scan(%r{[!"#%&'=\-^~¥\\|`@*:+;/?.,]+})
            tokens << ::Regexp.escape(s.matched.rstrip)
          when s.scan(/./)
            tokens << ::Regexp.escape(s.matched)
          end
        end

        if tokens.first =~ /\A\p{L}/
          tokens.first.prepend('\b')
        end

        if tokens.last =~ /\p{L}\Z/
          tokens.last << '\b'
        end

        options = ::Regexp::MULTILINE
        options |= ::Regexp::IGNORECASE unless case_sensitive

        ::Regexp.new(tokens.join('\s*').gsub(/\\s\*(\\s\+\\s\*)+/, '\s+'), options)
      end
    end
  end
end
