require_relative "test_helper"

class AnalyzerTest < Minitest::Test
  Analyzer = Goodcheck::Analyzer
  Issue = Goodcheck::Issue
  Buffer = Goodcheck::Buffer
  Rule = Goodcheck::Rule
  Pattern = Goodcheck::Pattern
  Location = Goodcheck::Location
  Trigger = Goodcheck::Trigger

  def buffer
    @buffer = Buffer.new(path: Pathname("foo.txt"), content: <<-EOF)
Lorem
ipsum
吾輩は猫である。
🍔
🐈
NSArray *a = [ NSMutableArray
               new ];
    EOF
  end

  def with_buffer(content, path: Pathname("foo.txt"))
    yield Buffer.new(path: path, content: content)
  end

  def new_rule(id:, message: "hello")
    Rule.new(id: id, message: message, triggers: [], justifications: [])
  end

  def new_trigger(negated: false, &block)
    Trigger.new(patterns: [], globs: [], passes: [], fails: [], negated: negated).tap(&block)
  end

  def test_analyzer
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern.literal("ipsum", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["ipsum"], issues.map(&:text)
    assert_equal [Location.new(start_line: 2, start_column: 0, end_line: 2, end_column: 5)], issues.map(&:location)
  end

  def test_analyzer_japanese
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern.literal("吾輩", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["吾輩"], issues.map(&:text)
    assert_equal [Location.new(start_line: 3, start_column: 0, end_line: 3, end_column: 6)], issues.map(&:location)
  end

  def test_analyzer_tokens
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern.token("[NSMutableArray new]", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["[ NSMutableArray
               new ]"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 13, end_line: 7, end_column: 20)], issues.map(&:location)
  end

  def test_analyzer_no_duplicate
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern.regexp("N.Array", case_sensitive: false, multiline: false)
        trigger.patterns << Pattern.regexp("NSAr.ay", case_sensitive: false, multiline: false)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["NSArray"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 0, end_line: 6, end_column: 7)], issues.map(&:location)
  end

  def test_analyzer_token_word_brake
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern.token("Array", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a
    assert_empty issues
  end

  def test_analyzer_token_word_brake2
    with_buffer(<<-CONTENT) do |buffer|
test1
test
atest
      CONTENT
      analyzer = Analyzer.new(
        buffer: buffer,
        rule: new_rule(id: "rule1"),
        trigger: new_trigger {|trigger|
          trigger.patterns << Pattern.regexp('(\btest\b|foo)', case_sensitive: false, multiline: false)
        }
      )

      assert_equal 1, analyzer.scan.count
    end
  end

  def test_analyzer_empty_pattern
    with_buffer(<<-CONTENT, path: Pathname("foo.txt")) do |buffer|
test1
test
atest
    CONTENT
      analyzer = Analyzer.new(
        buffer: buffer,
        rule: new_rule(id: "rule1"),
        trigger: new_trigger {|trigger|
          trigger.globs << Goodcheck::Glob.new(pattern: "*.txt", encoding: nil)
        }
      )

      issues = analyzer.scan.to_a

      assert_equal 1, issues.size
      assert_nil issues[0].range
      assert_nil issues[0].text
    end
  end
end
