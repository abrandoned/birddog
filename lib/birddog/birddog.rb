module Birddog

  def self.included(base)
    base.extend(::Birddog::Searchable)
  end

  class Birddog
    include ::Birddog::FieldConditions

    AREL_KEYS = [:select, :limit, :joins, :includes, :group, :from, :where, :having]
    attr_reader :fields

    def initialize(model)
      @model = model
      @fields = {}
      @averagable = []
      @minimumable = []
      @maximumable = []
      @sumable = []

      define_common_aggregates_for(model)
    end

    def field(name, options={}, &mapping)
      @fields[name] = field = {
        :attribute       => options.fetch(:attribute, name),
        :cast            => options.fetch(:cast, false),
        :type            => options.fetch(:type, :string),
        :case_sensitive  => options.fetch(:case_sensitive, true),
        :match_substring => options.fetch(:match_substring, false),
        :regex           => options.fetch(:regex, false),
        :wildcard        => options.fetch(:wildcard, false),
        :aggregate       => options.fetch(:aggregate, false),
        :options         => options.select { |k,v| AREL_KEYS.include?(k) }, 
        :mapping         => mapping || lambda{ |v| v }
      }

      aggregate?(name) ? define_aggregate_field(name, field) : define_field(name, field)
    end

    def aggregate?(name)
      @fields[name].fetch(:aggregate, false)
    end

    def alias_field(name, other_field)
      @fields[name] = @fields[other_field]
      aggregate?(name) ? define_aggregate_field(name, @fields[name]) : define_field(name, @fields[name])
    end

    def averagable(*fields)
      fields.flatten.each do |avg_field|
        @averagable << avg_field
      end
    end

    def minimumable(*fields)
      fields.flatten.each do |min_field|
        @minimumable << min_field
      end
    end

    def maximumable(*fields)
      fields.flatten.each do |max_field|
        @maximumable << max_field 
      end
    end

    def sumable(*fields)
      fields.flatten.each do |sum_field|
        @sumable << sum_field
      end
    end

    def keyword(name, &block)
      define_scope(name, &block)
    end

    def search(query)
      tokens = tokenize(query)
      tokens.inject(@model) do |model, (key,value)|
        key, value = "text_search", key if value.nil?
        scope_for(model, key, value)
      end
    end

    def text_search(*fields)
      options = fields.extract_options!
      fields = fields.map { |f| "LOWER(#{f}) LIKE :value" }.join(" OR ")

      define_scope "text_search" do |value|
        options.merge(:conditions => [fields, { :value => "%#{value.downcase}%" }])
      end
    end

    ################## PRIVATES ####################

    def conditional?(value)
      value.index(/[<>=]/) != nil   
    end
    private :conditional?

    def define_aggregate_field(name, field)
      field[:options].merge!(:select => field[:aggregate])

      define_scope(name) do |value|
        if conditional?(value)
          field[:options].merge(:having => setup_conditions(field, value))
        else
          field[:options]
        end
      end
    end
    private :define_aggregate_field

    def define_field(name, field)
      define_scope(name) do |value|
        field[:options].merge(:conditions => setup_conditions(field, value))
      end
    end
    private :define_field

    def scope_name_for(key)
      "_birddog_scope_#{key}"
    end
    private :scope_name_for

    def define_static_scope(name, &scope)
      @model.__send__(:scope, name, scope)
    end
    private :define_static_scope

    def define_scope(name, &scope)
      @model.__send__(:scope, scope_name_for(name), scope)
    end
    private :define_scope

    def callable_or_cast(field, condition, value)
      if field[:cast] && field[:cast].respond_to?(:call) 
        field[:cast].call(value.gsub(condition, ""))
      else
        cast_value(value, field[:type])
      end
    end
    private :callable_or_cast

    def cast_value(value, type)
      case type
      when :boolean then
        BooleanExpression.parse(value)
      when :float, :decimal, :integer then
        NumericExpression.new(value, type)
      when :date then
        DateExpression.new(value)
      when :time, :datetime then
        Chronic.parse(value)
      else
        value.strip
      end
    end
    private :cast_value

    def parse_condition(value)
      valid = %w(= == > < <= >= <>)
      value.gsub!(/\s/, '')

      parts = value.scan(/(?:[=<>]+)/)
      cond = parts.first
      valid.include?(cond) ? cond.strip : "="
    end
    private :parse_condition

    def setup_conditions(field, value)
      condition = parse_condition(value)
      value = callable_or_cast(field, condition, value) 
      value = field[:mapping].call(value)

      case field[:type]
      when :string then
        conditions_for_string_search(field, value)
      when :float, :decimal, :integer then
        conditions_for_numeric(field, condition, value)
      when :date, :datetime, :time then 
        conditions_for_date(field, condition, value)
      else
        { field[:attribute] => value }
      end
    end
    private :setup_conditions

    def tokenize(query)
      split_tokens = query.split(":")
      split_tokens.each { |tok| tok.strip! }

      [[split_tokens.shift, split_tokens.join(":")]]
    end
    private :tokenize

    def define_common_aggregates_for(model)
      _common_average_for(model)
      _common_sum_for(model)
      _common_minimum_for(model)
      _common_maximum_for(model)
    end
    private :define_common_aggregates_for

    def _common_average_for(model)
      define_static_scope(:_birddog_average) do |field, field_alias, value|
        field_name = "#{field_alias}#{field}"
        scope = { :select => @model.arel_table[field].average.as(field_name) }
        warn_common_aggregate_conditional if conditional?(value)
        scope
      end
    end
    private :_common_average_for

    def _common_sum_for(model)
      define_static_scope(:_birddog_sum) do |field, field_alias, value|
        field_name = "#{field_alias}#{field}"
        scope = { :select => @model.arel_table[field].sum.as(field_name) }
        warn_common_aggregate_conditional if conditional?(value)
        scope
      end
    end
    private :_common_sum_for
      
    def _common_minimum_for(model)
      define_static_scope(:_birddog_minimum) do |field, field_alias, value|
        field_name = "#{field_alias}#{field}"
        scope = { :select => @model.arel_table[field].minimum.as(field_name) }
        warn_common_aggregate_conditional if conditional?(value)
        scope
      end
    end
    private :_common_minimum_for

    def _common_maximum_for(model)
      define_static_scope(:_birddog_maximum) do |field, field_alias, value|
        field_name = "#{field_alias}#{field}"
        scope = { :select => @model.arel_table[field].maximum.as(field_name) }
        warn_common_aggregate_conditional if conditional?(value)
        scope
      end
    end
    private :_common_maximum_for

    def aggregate_scope_for(model, key, value)
      aggregate_scope = nil
      field_name = nil
      field_alias = nil
      key = key.to_s

      case 
      when key =~ /^(average_|avg_)([a-zA-Z_]*)/ && @averagable.include?($2.to_sym) then
        aggregate_scope = "_birddog_average"
        field_alias = $1
        field_name = $2
      when key =~ /^(sum_)([a-zA-Z_]*)/ && @sumable.include?($2.to_sym) then
        aggregate_scope = "_birddog_sum"
        field_alias = $1
        field_name = $2
      when key =~ /^(minimum_|min_)([a-zA-Z_]*)/ && @minimumable.include?($2.to_sym) then
        aggregate_scope = "_birddog_minimum"
        field_alias = $1
        field_name = $2
      when key =~ /^(maximum_|max_)([a-zA-Z_]*)/ && @maximumable.include?($2.to_sym) then
        aggregate_scope = "_birddog_maximum"
        field_alias = $1
        field_name = $2
      end

      [field_name, field_alias, aggregate_scope]
    end
    private :aggregate_scope_for
 
    def scope_for(model, key, value)
      field, field_alias, scope_name = aggregate_scope_for(model, key, value)
      scope_name = scope_name_for(key) unless scope_name

      if model.respond_to?(scope_name)
        send_params = [field, field_alias, value].compact
        model.__send__(scope_name, *send_params)
      else
        model.scoped
      end
    end
    private :scope_for

    def warn_common_aggregate_conditional
      raise "WARNING"
    rescue => e
      warn <<-WARNING
      ===================================================================
      Birddog currently does not process conditionals on common aggregates
      your program may not behave as expected.

      Called at:

      #{e.backtrace.join("#{$/}      ")}
      ===================================================================
      WARNING
    end

  end

end
