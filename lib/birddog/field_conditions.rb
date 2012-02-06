module Birddog

  module FieldConditions

    def conditions_for_string_search(current_scope, field, value)
      search_con = "=~"
      field_to_search = "lower(#{field[:attribute]})"
      value_to_search = value.downcase

      if field[:case_sensitive]
        field_to_search = field[:attribute]
        value_to_search = value
      end

      if field[:match_substring]
        value_to_search = "%#{value_to_search}%"
      end

      if field[:regex] && regexed?(value)
        # TODO check db driver to determine regex operator for DB (current is Postgres)
        value_to_search = value[1..value.size-2]
        field_to_search = field[:attribute]
      elsif field[:wildcard] && value_to_search.include?("*")
        value_to_search.gsub!(/[\*]/, "%")
      end

      conditionally_scoped(current_scope, field_to_search, search_con, value_to_search, field[:aggregate])
    end

    def conditions_for_date(current_scope, field, condition, value)
      conditionally_scoped(current_scope, field[:attribute], condition, value.value.strftime("%Y-%m-%d"), field[:aggregate])
    end

    def conditions_for_numeric(current_scope, field, condition, value, field_type)
      conditionally_scoped(current_scope, field[:attribute], condition, cast_numeric(field_type, value), field[:aggregate])
    end

    def cast_numeric(field_type, value)
      case field_type
      when :integer then
        value.to_i
      else
        value.to_f
      end
    end

    def conditionally_scoped(current_scope, field, condition, value, aggregate)
      scope = case condition
      when "=~" then
        current_scope.where( "#{field} LIKE ? ", value) unless aggregate
      when :<, "<" then
        current_scope.where{ __send__(field) < value } unless aggregate
      when :>, ">" then
        current_scope.where{ __send__(field) > value } unless aggregate
      when :<=, "<=", "=<" then
        current_scope.where{ __send__(field) <= value } unless aggregate
      when :>=, ">=", "=>" then
        current_scope.where{ __send__(field) >= value } unless aggregate
      when "=" then
        current_scope.where{ __send__(field) == value } unless aggregate
      else
        raise "#{condition} not defined for #{field}"
      end

      scope = current_scope.having("#{field} #{condition} ? ", value) if aggregate 
      return scope
    end

    def regexed?(value)
      (value[0].chr == '/' && value[-1].chr == '/')
    end

  end

end
