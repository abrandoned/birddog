require "spec_helper"

describe ::Birddog::FieldConditions do ##############
  class RegexTestClass
    extend ::Birddog::FieldConditions
  end

  ["/regex/",
    "/man on a buffalo//",
    " /straight up mauled/",
    "/by a cougar/ ",
    " /buffalo/ "].each do |reg|
    it "identifies #{reg} as regex" do 
      RegexTestClass.regexed?(reg.strip).must_equal(true)
    end
  end

  ["regex/",
    "/man on a buffalo",
    " /straight up mauled/ and stuff"].each do |reg|
    it "doesnt identify #{reg} as regex" do 
      RegexTestClass.regexed?(reg.strip).must_equal(false)
    end
  end
end
