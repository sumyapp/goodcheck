module Goodcheck
  class ConfigLoader
    include ArrayHelper

    class InvalidPattern < StandardError; end

    Schema = StrongJSON.new do
      let :deprecated_regexp_pattern, object(regexp: string, case_insensitive: boolean?, multiline: boolean?)
      let :deprecated_literal_pattern, object(literal: string, case_insensitive: boolean?)
      let :deprecated_token_pattern, object(token: string, case_insensitive: boolean?)

      let :regexp_pattern, object(regexp: string, case_sensitive: boolean?, multiline: boolean?)
      let :literal_pattern, object(literal: string, case_sensitive: boolean?)
      let :token_pattern, object(token: string, case_sensitive: boolean?)

      let :pattern, enum(regexp_pattern, literal_pattern, token_pattern,
                         deprecated_regexp_pattern, deprecated_literal_pattern, deprecated_token_pattern,
                         string)

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

      let :import_target, string
      let :imports, array(import_target)
      let :exclude, enum(array(string), string)

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
      patterns = retrieve_patterns(hash)
      justifications = array(hash[:justification])
      globs = load_globs(array(hash[:glob]))
      message = hash[:message].chomp
      passes = array(hash[:pass])
      fails = array(hash[:fail])

      Rule.new(id: id, patterns: patterns, justifications: justifications, globs: globs, message: message, passes: passes, fails: fails)
    end

    def retrieve_patterns(hash)
      array(hash[:pattern]).map do |pat|
        load_pattern(pat)
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
