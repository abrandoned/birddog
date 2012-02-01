module Birddog

  class NumericExpression

    def initialize(value, type)
      value.gsub!(/\s/, '')
      parts = value.scan(/(?:[=<>]+|(?:-?\d|\.)+)/)[0,2]

      @value = Float(parts.last)
      @value = @value.to_i if type == :integer
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
