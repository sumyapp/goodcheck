module Goodcheck
  class Config
    attr_reader :rules
    attr_reader :exclude_paths

    def initialize(rules:, exclude_paths:)
      @rules = rules
      @exclude_paths = exclude_paths
    end

    def each_rule(filter:, &block)
      if block_given?
        if filter.empty?
          rules.each(&block)
        else
          rules.each do |rule|
            if filter.any? {|rule_id| rule.id == rule_id || rule.id.start_with?("#{rule_id}.") }
              yield rule
            end
          end
        end
      else
        enum_for :each_rule, filter: filter
      end
    end

    def rules_for_path(path, rules_filter:)
      if block_given?
        each_rule(filter: rules_filter).map do |rule|
          rule.triggers.each do |trigger|
            globs = trigger.globs

            if globs.empty?
              yield [rule, nil, trigger]
            else
              glob = globs.find {|glob| glob.test(path) }
              if glob
                yield [rule, glob, trigger]
              end
            end
          end
        end
      else
        enum_for(:rules_for_path, path, rules_filter: rules_filter)
      end
    end
  end
end
