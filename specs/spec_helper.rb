require 'rubygems'
require 'bundler'
Bundler.require(:default, :development, :test)

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/pride'
require 'support/minitest_matchers'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "specs/test.db"
)

ActiveRecord::Base.connection.tables.each do |table|
  ActiveRecord::Base.connection.drop_table(table)
end

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :first_name
    t.string :last_name
  end

  create_table :products do |t|
    t.string :name
    t.decimal :value
    t.boolean :available, :default => true
    t.belongs_to :user
  end
end

class User < ActiveRecord::Base
  include Birddog

  has_many :products

  birddog do |search|
    search.field :first_name
    search.alias_field :name, :first_name
    search.field :last_name
    search.field :total_product_value, :type => :decimal, :aggregate => "SUM(products.value) AS total_product_value"
    search.field :insensitive_last_name, :attribute => "last_name", :case_sensitive => false
    search.field :substringed_last_name, :attribute => "last_name", :match_substring => true
    search.field :available_product, :type => :boolean,
                                     :attribute => "products.available",
                                     :joins => :products

    search.keyword :aggregate_user do 
      select(arel_table[:id]).
        joins("LEFT OUTER JOIN products AS products ON (products.user_id = users.id)").
        group(arel_table[:id])
    end

    search.text_search "first_name", "last_name", "products.name", :include => :products
  end
end

class Product < ActiveRecord::Base
  include Birddog

  belongs_to :user

  birddog do |search|
    search.averagable :value
    search.minimumable :value
    search.maximumable :value
    search.sumable :value
    search.text_search "products.name", "products.value"

    search.field :name, :regex => true, :wildcard => true
    search.field :cast_val, :type => :decimal, :cast => lambda { |v| v }, :attribute => :value
    search.field :value, :type => :decimal
    search.field :available, :type => :boolean

    search.keyword :sort do |value|
      { :order => "#{search.fields[value.to_sym][:attribute]} DESC" }
    end
  end
end
