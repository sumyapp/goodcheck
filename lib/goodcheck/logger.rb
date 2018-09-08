module Goodcheck
  def self.logger
    @logger ||= ActiveSupport::TaggedLogging.new(Logger.new(STDERR)).tap do |logger|
      logger.push_tags VERSION
      logger.level = Logger::ERROR
    end
  end
end
