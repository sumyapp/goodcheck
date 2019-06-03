module Goodcheck
  class ConfigLoader
    include ArrayHelper

    class InvalidPattern < StandardError; end

    Schema = StrongJSON.new do
      def self.array_or(type)
        a = array(type)
        enum(a, type, detector: -> (value) {
          case value
          when Array
            a
          else
            type
          end
        })
      end

      let :deprecated_regexp_pattern, object(regexp: string, case_insensitive: boolean?, multiline: boolean?)
      let :deprecated_literal_pattern, object(literal: string, case_insensitive: boolean?)
      let :deprecated_token_pattern, object(token: string, case_insensitive: boolean?)

      let :encoding, enum(*Encoding.name_list.map {|name| literal(name) })
      let :glob_obj, object(pattern: string, encoding: optional(encoding))
      let :one_glob, enum(glob_obj,
                          string,
                          detector: -> (value) {
                            case value
                            when Hash
                              glob_obj
                            when String
                              string
                            end
                          })
      let :glob, array_or(one_glob)

      let :regexp_pattern, object(regexp: string, case_sensitive: boolean?, multiline: boolean?, glob: optional(glob))
      let :literal_pattern, object(literal: string, case_sensitive: boolean?, glob: optional(glob))
      let :token_pattern, object(token: string, case_sensitive: boolean?, glob: optional(glob))

      let :pattern, enum(regexp_pattern,
                         literal_pattern,
                         token_pattern,
                         deprecated_regexp_pattern,
                         deprecated_literal_pattern,
                         deprecated_token_pattern,
                         string,
                         detector: -> (value) {
                           case value
                           when Hash
                             case
                             when value.key?(:regexp) && value.key?(:case_insensitive)
                               deprecated_regexp_pattern
                             when value.key?(:regexp)
                               regexp_pattern
                             when value.key?(:literal) && value.key?(:case_insensitive)
                               deprecated_literal_pattern
                             when value.key?(:literal)
                               literal_pattern
                             when value.key?(:token) && value.key?(:case_insensitive)
                               deprecated_token_pattern
                             when value.key?(:token)
                               token_pattern
                             end
                           when String
                             string
                           end
                         })

      let :positive_rule, object(
        id: string,
        pattern: array_or(pattern),
        message: string,
        justification: optional(array_or(string)),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string))
      )

      let :negative_rule, object(
        id: string,
        not: object(pattern: array_or(pattern)),
        message: string,
        justification: optional(array_or(string)),
        glob: optional(glob),
        pass: optional(array_or(string)),
        fail: optional(array_or(string))
      )

      let :nopattern_rule, object(
        id: string,
        message: string,
        justification: optional(array_or(string)),
        glob: glob
      )

      let :rule, enum(positive_rule,
                      negative_rule,
                      nopattern_rule,
                      detector: -> (hash) {
                        if hash.is_a?(Hash)
                          case
                          when hash[:pattern]
                            positive_rule
                          when hash[:not]
                            negative_rule
                          when hash.key?(:glob) && !hash.key?(:pattern) && !hash.key?(:not)
                            nopattern_rule
                          end
                        end
                      })

      let :rules, array(rule)

      let :import_target, string
      let :imports, array(import_target)
      let :exclude, array_or(string)

      let :config, object(
        rules: rules,
        import: optional(imports),
        exclude: optional(exclude)
      )
    end

    attr_reader :path
    attr_reader :content
    attr_reader :stderr
    attr_reader :printed_warnings
    attr_reader :import_loader

    def initialize(path:, content:, stderr:, import_loader:)
      @path = path
      @content = content
      @stderr = stderr
      @printed_warnings = Set.new
      @import_loader = import_loader
    end

    def load
      Goodcheck.logger.info "Loading configuration: #{path}"
      Goodcheck.logger.tagged "#{path}" do
        Schema.config.coerce(content)

        rules = []

        load_rules(rules, content[:rules])

        Array(content[:import]).each do |import|
          load_import rules, import
        end

        exclude_paths = Array(content[:exclude])

        Config.new(rules: rules, exclude_paths: exclude_paths)
      end
    end

    def load_rules(rules, array)
      array.each do |hash|
        rules << load_rule(hash)
      end
    end

    def load_import(rules, import)
      Goodcheck.logger.info "Importing rules from #{import}"

      Goodcheck.logger.tagged import do
        import_loader.load(import) do |content|
          json = JSON.parse(JSON.dump(YAML.load(content, import)), symbolize_names: true)

          Schema.rules.coerce json
          load_rules(rules, json)
        end
      end
    end

    def load_rule(hash)
      Goodcheck.logger.debug "Loading rule: #{hash[:id]}"

      id = hash[:id]
      triggers = retrieve_triggers(hash)
      justifications = array(hash[:justification])
      message = hash[:message].chomp

      Rule.new(id: id, message: message, justifications: justifications, triggers: triggers)
    end

    def retrieve_triggers(hash)
      patterns, negated = retrieve_patterns(hash)
      globs = load_globs(array(hash[:glob]))
      passes = array(hash[:pass])
      fails = array(hash[:fail])

      [
        Trigger.new(patterns: patterns,
                    globs: globs,
                    passes: passes,
                    fails: fails,
                    negated: negated)
      ]
    end

    def retrieve_patterns(hash)
      if hash.is_a?(Hash) && hash.key?(:not)
        negated = true
        hash = hash[:not]
      else
        negated = false
      end

      if hash.key?(:pattern)
        [array(hash[:pattern]).map {|pat| load_pattern(pat) }, negated]
      else
        [[], false]
      end
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
        Pattern.literal(pattern, case_sensitive: true)
      when Hash
        if pattern[:glob]
          print_warning_once "🌏 Pattern with glob is deprecated: globs are ignored at all."
        end

        case
        when pattern[:literal]
          cs = case_sensitive?(pattern)
          literal = pattern[:literal]
          Pattern.literal(literal, case_sensitive: cs)
        when pattern[:regexp]
          regexp = pattern[:regexp]
          cs = case_sensitive?(pattern)
          multiline = pattern[:multiline]
          Pattern.regexp(regexp, case_sensitive: cs, multiline: multiline)
        when pattern[:token]
          tok = pattern[:token]
          cs = case_sensitive?(pattern)
          Pattern.token(tok, case_sensitive: cs)
        end
      end
    end

    def case_sensitive?(pattern)
      return true if pattern.is_a?(String)
      case
      when pattern.key?(:case_sensitive)
        pattern[:case_sensitive]
      when pattern.key?(:case_insensitive)
        print_warning_once "👻 `case_insensitive` option is deprecated. Use `case_sensitive` option instead."
        !pattern[:case_insensitive]
      else
        true
      end
    end

    def print_warning_once(message)
      unless printed_warnings.include?(message)
        stderr.puts "[Warning] " + message
        printed_warnings << message
      end
    end
  end
end
