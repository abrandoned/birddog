# (The MIT License)
# 
# Copyright (c) 2010 Nicolas Sanguinetti, http://nicolassanguinetti.info
# Copyright (c) 2012 Brandon Dewitt, http://abrandoned.com
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), 
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
# IN THE SOFTWARE.

require "chronic"
require "active_record"

require "birddog/version"
require "birddog/field_conditions"
require "birddog/boolean_expression"
require "birddog/date_expression"
require "birddog/numeric_expression"
require "birddog/searchable"

module Birddog

  def self.included(base)
    base.extend(::Birddog::Searchable)
  end

  class Birddog
    include ::Birddog::FieldConditions

    attr_reader :fields

    def initialize(model)
      @model = model
      @fields = {}
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
        :options         => options.except(:attribute, :type, :case_sensitive, :match_substring, :regex, :wildcard, :aggregate, :cast),
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

    def define_scope(name, &scope)
      @model.send(:scope, scope_name_for(name), scope)
    end
    private :define_scope


    def callable_or_cast(field, value)
      if field[:cast] && field[:cast].respond_to?(:call) 
        field[:cast].call(value)
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
      value = callable_or_cast(field, value) 
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

    def scope_for(model, key, value)
      scope_name = scope_name_for(key)

      if model.respond_to?(scope_name)
        model.send(scope_name, value)
      else
        model.scoped
      end
    end
    private :scope_for

  end

end
