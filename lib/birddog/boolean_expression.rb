module Birddog

  class BooleanExpression

    def self.parse(value)
      { "true"  => true,
        "yes"   => true,
        "y"     => true,
        "false" => false,
        "no"    => false,
        "n"     => false }.fetch("#{value.downcase}", true)
    end

  end

end
