module Goodcheck
  class ConfigLoader
    include ArrayHelper

    class InvalidPattern < StandardError; end

    Schema = StrongJSON.new do
      let :regexp_pattern, object(regexp: string, case_insensitive: boolean?, multiline: boolean?)
      let :literal_pattern, object(literal: string, case_insensitive: boolean?)
      let :token_pattern, object(token: string)
      let :pattern, enum(regexp_pattern, literal_pattern, token_pattern, string)

      let :encoding, enum(*Encoding.name_list.map {|name| literal(name) })
      let :glob, object(pattern: string, encoding: optional(encoding))

      let :rule, object(
        id: string,
        pattern: enum(array(pattern), pattern),
        message: string,
        justification: optional(enum(array(string), string)),
        glob: optional(enum(array(enum(glob, string)), glob, string)),
        pass: optional(enum(array(string), string)),
        fail: optional(enum(array(string), string))
      )

      let :rules, array(rule)

      let :config, object(rules: rules)
    end

    attr_reader :path
    attr_reader :content

    def initialize(path:, content:)
      @path = path
      @content = content
    end

    def load
      Schema.config.coerce(content)
      rules = content[:rules].map {|hash| load_rule(hash) }
      Config.new(rules: rules)
    end

    def load_rule(hash)
      id = hash[:id]
      patterns = array(hash[:pattern]).map {|pat| load_pattern(pat) }
      justifications = array(hash[:justification])
      globs = load_globs(array(hash[:glob]))
      message = hash[:message].chomp
      passes = array(hash[:pass])
      fails = array(hash[:fail])

      Rule.new(id: id, patterns: patterns, justifications: justifications, globs: globs, message: message, passes: passes, fails: fails)
    end

    def load_globs(globs)
      globs.map do |glob|
        case glob
        when String
          Glob.new(pattern: glob, encoding: nil)
        when Hash
          Glob.new(pattern: glob[:pattern], encoding: glob[:encoding])
        end
      end
    end

    def load_pattern(pattern)
      case pattern
      when String
        Pattern.literal(pattern, case_insensitive: false)
      when Hash
        case
        when pattern[:literal]
          ci = pattern[:case_insensitive]
          literal = pattern[:literal]
          Pattern.literal(literal, case_insensitive: ci)
        when pattern[:regexp]
          regexp = pattern[:regexp]
          ci = pattern[:case_insensitive]
          multiline = pattern[:multiline]
          Pattern.regexp(regexp, case_insensitive: ci, multiline: multiline)
        when pattern[:token]
          tok = pattern[:token]
          Pattern.token(tok)
        end
      end
    end
  end
end
