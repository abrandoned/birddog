module Birddog

  class DateExpression
    attr_reader :value, :condition

    def initialize(value)
      # allow additional spaces to be entered between conditions and value
      value.gsub!(/\s/, '')
      parts = value.scan(/(?:[=<>]+|(?:[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}))/)[0,2]
      @value = Date.parse(Chronic.parse(parts.last).to_s)
      @condition = sanitize_condition(parts.first)
    end

    def sanitize_condition(cond)
      valid = %w(= == > < <= >= <>)
      valid.include?(cond) ? cond.strip : "="
    end

    def to_s
      @value.to_s
    end
  end

end
