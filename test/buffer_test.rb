require_relative "test_helper"

class BufferTest < Minitest::Test
  Buffer = Goodcheck::Buffer

  CONTENT = <<-EOF
Lorem
ipsum
吾輩は猫である。
🍔
🐈
  EOF

  def assert_string_range(string, expected, actual)
    assert_equal expected, actual
    assert_equal string.byteslice(expected), string.byteslice(actual)
  end

  def test_line_starts
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_string_range CONTENT, 0...5, buffer.line_ranges[0]
    assert_string_range CONTENT, 6...11, buffer.line_ranges[1]
    assert_string_range CONTENT, 12...36, buffer.line_ranges[2]
    assert_string_range CONTENT, 37...41, buffer.line_ranges[3]
    assert_string_range CONTENT, 42...46, buffer.line_ranges[4]
    assert_string_range CONTENT, 47...47, buffer.line_ranges[5]
    assert_nil buffer.line_ranges[6]
  end

  def test_location_for_position
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal [1,0], buffer.location_for_position(0)
    assert_equal [1,1], buffer.location_for_position(1)
    assert_equal [1,4], buffer.location_for_position(4)
    assert_equal [1,5], buffer.location_for_position(5)
    assert_equal [2,0], buffer.location_for_position(6)
    assert_equal [3,0], buffer.location_for_position(12)
    assert_equal [4,0], buffer.location_for_position(37)
    assert_equal [5,0], buffer.location_for_position(42)
    assert_equal [6,0], buffer.location_for_position(47)
    assert_nil buffer.location_for_position(120)
  end

  def test_position_for_location
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal 0, buffer.position_for_location(1, 0)
    assert_equal 1, buffer.position_for_location(1, 1)
    assert_equal 4, buffer.position_for_location(1, 4)
    assert_equal 5, buffer.position_for_location(1, 5)
    assert_equal 6, buffer.position_for_location(2, 0)
    assert_nil buffer.position_for_location(100, 0)
  end
end

