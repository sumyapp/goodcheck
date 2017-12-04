module Goodcheck
  class Location
    attr_reader :start_line
    attr_reader :start_column
    attr_reader :end_line
    attr_reader :end_column

    def initialize(start_line:, start_column:, end_line:, end_column:)
      @start_line = start_line
      @start_column = start_column
      @end_line = end_line
      @end_column = end_column
    end

    def ==(other)
      other.is_a?(Location) &&
        other.start_line == start_line &&
        other.start_column == start_column &&
        other.end_line == end_line &&
        other.end_column == end_column
    end
  end
end
