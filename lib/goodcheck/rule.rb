module Goodcheck
  class Rule
    attr_reader :id
    attr_reader :triggers
    attr_reader :message
    attr_reader :justifications

    def initialize(id:, triggers:, message:, justifications:)
      @id = id
      @triggers = triggers
      @message = message
      @justifications = justifications
    end
  end
end
