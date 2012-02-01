module Birddog

  class DateExpression
    attr_reader :value

    def initialize(value)
      value.gsub!(/\s/, '')
      parts = value.scan(/(?:[=<>]+|(?:[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}))/)[0,2]
      @value = Date.parse(Chronic.parse(parts.last).to_s)
    end

    def to_s
      @value.to_s
    end

  end

end
