module Birddog

  class ScopeBuilder

    def self.build(model, scope_options)
      new(model, scope_options).build
    end
    
    def initialize(model, scope_options)
      @options = scope_options
      @model = model
    end

    def build
      scope = @model.scoped
      
      @options.each do |k, v|
        scope = scope.__send__(k, v)
      end
      
      return scope
    end

  end
  
end
