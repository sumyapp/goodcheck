module Goodcheck
  class Matcher
    attr_reader :path
    attr_reader :src
    attr_reader :rule

    def initialize(path:, src:, rule:)
      @path = path
      @src = src
      @rule = rule
    end

    def each
      if block_given?

      else
        enum_for :each
      end
    end
  end
end
