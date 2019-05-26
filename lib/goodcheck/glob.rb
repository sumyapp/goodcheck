module Goodcheck
  class Glob
    attr_reader :pattern
    attr_reader :encoding

    def initialize(pattern:, encoding:)
      @pattern = pattern
      @encoding = encoding
    end

    def test(path)
      path.fnmatch?(pattern, File::FNM_PATHNAME | File::FNM_EXTGLOB)
    end
  end
end
