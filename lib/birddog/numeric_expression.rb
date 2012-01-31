module Birddog

  class NumericExpression

    attr_reader :condition

    def initialize(value, type)
      # allow additional spaces to be entered between conditions and value
      value.gsub!(/\s/, '')
      parts = value.scan(/(?:[=<>]+|(?:-?\d|\.)+)/)[0,2]

      @value = Float(parts.last)
      @value = @value.to_i if type == :integer
      @condition = sanitize_condition(parts.first)
    end

    def sanitize_condition(cond)
      valid = %w(= == > < <= >= <>)
      valid.include?(cond) ? cond.strip : "="
    end

    def to_i
      @value.to_i
    end

    def to_f
      @value.to_f
    end

    def to_s
      @value.to_s
    end
  end

end
