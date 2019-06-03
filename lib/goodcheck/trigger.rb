module Goodcheck
  class Trigger
    attr_reader :patterns
    attr_reader :globs
    attr_reader :passes
    attr_reader :fails
    attr_reader :negated

    def initialize(patterns:, globs:, passes:, fails:, negated:)
      @patterns = patterns
      @globs = globs
      @passes = passes
      @fails = fails
      @negated = negated
    end

    def negated?
      @negated
    end

    def fires_for?(path:)
      globs.any? {|glob| glob.test(path) }
    end
  end
end
