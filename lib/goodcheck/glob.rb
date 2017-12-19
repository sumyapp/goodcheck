module Goodcheck
  class Glob
    attr_reader :pattern
    attr_reader :encoding

    def initialize(pattern:, encoding:)
      @pattern = pattern
      @encoding = encoding
    end
  end
end
