require "spec_helper"

describe Birddog::Birddog do
  before :each do
    User.destroy_all
    Product.destroy_all
    @john = User.create(:first_name => "John", :last_name => "Doe")
    @ducky = @john.products.create(:name => "Rubber Duck", :value => 10)
    @tv = @john.products.create(:name => "TV", :value => 200)
    @bike = @john.products.create(:name => "Bike", :value => 100)
  end

  describe "castable" do 
    it "casts Date when a cast function is provided" do 
      prods = Product.scopes_for_query("cast_val:10")
      prods.must_include(@ducky)
    end

    it "casts Date when a cast function is provided and is <=" do 
      prods = Product.scopes_for_query("cast_val:<=11")
      prods.must_include(@ducky)
    end

    it "casts Date when a cast function is provided and is >" do 
      prods = Product.scopes_for_query("cast_val:>9")
      prods.must_include(@ducky)
    end
  end

  describe "aggregates" do 
    it "doesn't include HAVING clause when no condition included" do 
      sql = User.scopes_for_query("aggregate_user").scopes_for_query("total_product_value").to_sql
      sql.wont_match(/HAVING/i)
    end

    it "includes HAVING clause when condition included" do 
      sql = User.scopes_for_query("aggregate_user").scopes_for_query("total_product_value:>0").to_sql
      sql.must_match(/HAVING/i)
    end

    it "calculates sums" do 
      sum = User.scopes_for_query("aggregate_user").
        scopes_for_query("total_product_value:>0")

      db_sum = User.first.products.inject(0.0) {|a,n| a + n.value }
      sum.first.total_product_value.must_equal(db_sum)
    end
  end

  describe "chained scopes" do 
    it "chains numeric" do 
      products = Product.scopes_for_query("value: > 11").
        scopes_for_query("value: < 101")

      products.size.must_equal(1)
      products.must_include(@bike)
    end

    it "chains numeric/wildcard" do 
      products = Product.scopes_for_query("value: > 11").
        scopes_for_query("value: < 300").
        scopes_for_query("name: T*")

      products.size.must_equal(1)
      products.must_include(@tv)
    end
  end

end
