module Birddog

  module Searchable

    def birddog(&block)
      @birddog ||= ::Birddog::Birddog.new(self)
      block ? @birddog.tap(&block) : @birddog
    end

    def scopes_for_query(query)
      birddog.search(query)
    end

  end

end
