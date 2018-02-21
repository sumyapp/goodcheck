require "tmpdir"

class TestCaseBuilder
  attr_reader :path

  def initialize(path:)
    @path = path
    @config_name = Pathname("goodcheck.yml")
  end

  attr_accessor :config_name

  def config_path
    path + config_name
  end

  def config(content:)
    config_path.write(content)
  end

  def dir(name)
    (path + name).mkpath
  end

  def file(name:, content:)
    dir (path + name).parent
    (path + name).write(content.force_encoding(Encoding::ASCII_8BIT))
  end

  def symlink(name:, original:)
    (path + name).make_symlink(original)
  end

  def self.tmpdir
    Dir.mktmpdir do |dir|
      yield self.new(path: Pathname(dir))
    end
  end

  def cd(&block)
    Dir.chdir path.to_s, &block
  end
end
