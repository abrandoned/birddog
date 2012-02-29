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

  describe "averagable" do 
    it "implements the common average scope" do 
      Product.must_respond_to(:_birddog_average)
    end

    it "creates a query on the column desired when scope is average_*" do 
      sql = Product.scopes_for_query("average_value").to_sql
      sql.must_match(/value/)
    end

    it "calculates the average and returns it in the result set" do 
      avg = Product.scopes_for_query("average_value").first
      avg.average_value.must_equal((100 + 200 + 10) / 3.0)
    end
  end

  describe "minimumable" do 
    it "implements the common minimum scope" do 
      Product.must_respond_to(:_birddog_minimum)
    end

    it "creates a query on the column desired when scope is minimum_*" do 
      sql = Product.scopes_for_query("minimum_value").to_sql
      sql.must_match(/minimum/)
    end

    it "calculates the minimum and returns it in the result set" do 
      avg = Product.scopes_for_query("minimum_value").first
      avg.minimum_value.must_equal(10)
    end
  end

  describe "maximumable" do 
    it "implements the common maximum scope" do 
      Product.must_respond_to(:_birddog_maximum)
    end

    it "creates a query on the column desired when scope is maximum_*" do 
      sql = Product.scopes_for_query("maximum_value").to_sql
      sql.must_match(/maximum/)
    end

    it "calculates the maximum and returns it in the result set" do 
      avg = Product.scopes_for_query("maximum_value").first
      avg.maximum_value.must_equal(200)
    end
  end

  describe "sumable" do 
    it "implements the common sum scope" do 
      Product.must_respond_to(:_birddog_sum)
    end

    it "creates a query on the column desired when scope is sum_*" do 
      sql = Product.scopes_for_query("sum_value").to_sql
      sql.must_match(/sum/)
    end

    it "calculates the sum and returns it in the result set" do 
      avg = Product.scopes_for_query("sum_value").first
      avg.sum_value.must_equal(310)
    end
  end
end
