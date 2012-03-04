module Birddog

  module FieldConditions

    def conditions_for_string_search(current_scope, field, value)
      search_con = "=~"
      value_to_search = value.dup

      if field[:match_substring]
        value_to_search = "%#{value_to_search}%"
      end

      if field[:regex] && regexed?(value)
        # TODO check db driver to determine regex operator for DB (current is Postgres)
        value_to_search = value[1..value.size-2]
      elsif field[:wildcard] && value_to_search.include?("*")
        value_to_search.gsub!(/[\*]/, "%")
      end

      conditionally_scoped(current_scope, field[:attribute], search_con, value_to_search, field[:aggregate])
    end

    def conditions_for_date(current_scope, field, condition, value)
      conditionally_scoped(current_scope, field[:attribute], condition, value.value.strftime("%Y-%m-%d"), field[:aggregate])
    end

    def conditions_for_numeric(current_scope, field, condition, value, field_type)
      conditionally_scoped(current_scope, field[:attribute], condition, cast_numeric(field_type, value), field[:aggregate], true)
    end

    def cast_numeric(field_type, value)
      case field_type
      when :integer then
        value.to_i
      else
        value.to_f
      end
    end

    def conditionally_scoped(current_scope, field, condition, value, aggregate, is_numeric = false)
      having_or_where = (aggregate ? :having : :where)
      scope = case condition
      when "=~", "~=" then
        if is_numeric
          current_scope.__send__(having_or_where, field.gteq(value.floor).and(field.lt((value + 1).floor))) 
        else
          current_scope.__send__(having_or_where, field.matches(value))
        end
      when :<, "<" then
        current_scope.__send__(having_or_where, field.lt(value))
      when :>, ">" then
        current_scope.__send__(having_or_where, field.gt(value))
      when :<=, "<=", "=<" then
        current_scope.__send__(having_or_where, field.lteq(value))
      when :>=, ">=", "=>" then
        current_scope.__send__(having_or_where, field.gteq(value))
      when "=" then
        current_scope.__send__(having_or_where, field.eq(value))
      else
        raise "#{condition} not defined for #{field}"
      end

      return scope
    end

    def regexed?(value)
      (value[0].chr == '/' && value[-1].chr == '/')
    end

  end

end
