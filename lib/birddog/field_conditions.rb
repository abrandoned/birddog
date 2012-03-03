module Birddog

  module FieldConditions

    FieldConversions = {
      :integer => lambda{ |v| v.to_i },
      :decimal => lambda{ |v| v.to_f },
      :float => lambda{ |v| v.to_f }
    }

    def conditions_for_string_search(field, value)
      search_con = " LIKE ? "
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
        search_con = " ~ ? "
        value_to_search = value[1..value.size-2]
        field_to_search = field[:attribute]
      elsif field[:wildcard] && value_to_search.include?("*")
        value_to_search.gsub!(/[\*]/, "%")
      end

      [ "#{field_to_search} #{search_con} ", value_to_search ]
    end

    def conditions_for_date(field, condition, value)
      [ "#{field[:attribute]} #{condition} ? ", value.value.strftime("%Y-%m-%d")]
    end

    def conditions_for_numeric(field, condition, value)
      db_value = FieldConversions[field[:type]].call(value)

      case condition
      when "=~", "~=" then
        [ "ABS(#{field[:attribute]}) >= ? AND ABS(#{field[:attribute]}) < ?", db_value.abs.floor, (db_value.abs + 1).floor ]
      else
        [ "#{field[:attribute]} #{condition} ? ", db_value]
      end
    end

    def regexed?(value)
      (value[0].chr == '/' && value[-1].chr == '/')
    end

  end

end
