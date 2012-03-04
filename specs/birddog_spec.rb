require "spec_helper"

describe Birddog::Birddog do ####################
  before :each do
    User.destroy_all
    Product.destroy_all
    @john = User.create(:first_name => "John", :last_name => "Doe")
    @ducky = @john.products.create(:name => "Rubber Duck", :value => 10)
    @apple_duck = @john.products.create(:name => "Apple Duck", :value => 10.38)
    @tv = @john.products.create(:name => "TV", :value => 200)
  end

  it "finds a user by first_name" do
    User.scopes_for_query("first_name:John").must_include(@john)
  end

  it "finds a user by first_name, using an alias" do
    User.scopes_for_query("name:John").must_include(@john)
  end

  it "finds by text search" do
    Product.scopes_for_query("duck rubber").must_include(@ducky)
  end

  #  TODO figure out the cross platform way
  #  it "finds by regex search" do 
  #    Product.scopes_for_query("name : /TV/").must_include(@tv)
  #  end

  it "finds by wildcard character" do 
    Product.scopes_for_query("name : T*").must_include(@tv)
  end

  it "finds a user by last_name, but only in a case sensitive manner" do
    User.scopes_for_query("last_name:Doe").must_include(@john)
    User.scopes_for_query("last_name:Doe").size.must_equal(1)
  end

  it "can find using case insensitive search" do
    User.scopes_for_query("insensitive_last_name:doe").must_include(@john)
    User.scopes_for_query("insensitive_last_name:doe").size.must_equal(1)
  end

  it "can find matching substrings" do
    User.scopes_for_query("substringed_last_name:oe").must_include(@john)
    User.scopes_for_query("substringed_last_name:oe").size.must_equal(1)
  end

  it "can find using key:value pairs for attributes that define a type" do
    User.scopes_for_query("available_product:yes").must_include(@john)
    User.scopes_for_query("available_product:no").wont_include(@john)
  end

  it "allows defining arbitrary keywords to create scopes" do
    @john.products.scopes_for_query("sort:name").all.must_equal([@tv, @ducky, @apple_duck])
  end

  describe "numeric fields" do ########################
    it "searches by equals" do
      @john.products.scopes_for_query("value:=10").must_include(@ducky)
      @john.products.scopes_for_query("value:=10").wont_include(@apple_duck)
      @john.products.scopes_for_query("value:=10").size.must_equal(1)
    end

    it "includes range in ~= search" do 
      @john.products.scopes_for_query("value:~=10").must_include(@ducky)
      @john.products.scopes_for_query("value:~=10").must_include(@apple_duck)
      @john.products.scopes_for_query("value:~=10").size.must_equal(2)
    end

    it "includes range in =~ search" do 
      @john.products.scopes_for_query("value:=~10").must_include(@ducky)
      @john.products.scopes_for_query("value:=~10").must_include(@apple_duck)
      @john.products.scopes_for_query("value:=~10").size.must_equal(2)
    end

    it "searches by equality without =" do 
      @john.products.scopes_for_query("value:10").must_include(@ducky)
      @john.products.scopes_for_query("value:10").size.must_equal(1)
    end

    it "searches by greater than" do 
      @john.products.scopes_for_query("value:>100").must_include(@tv)
      @john.products.scopes_for_query("value:>100").size.must_equal(1)
    end

    it "searches by less than" do 
      @john.products.scopes_for_query("value:<100").must_include(@ducky)
      @john.products.scopes_for_query("value:<100").must_include(@apple_duck)
      @john.products.scopes_for_query("value:<100").size.must_equal(2)
    end

    it "searches by =>" do
      @john.products.scopes_for_query("value:>=200").must_include(@tv)
      @john.products.scopes_for_query("value:>=200").size.must_equal(1)
    end

    it "searches on negatives" do 
      @john.products.scopes_for_query("value:>=-200").must_include(@tv)
      @john.products.scopes_for_query("value:>=-200").must_include(@ducky)
      @john.products.scopes_for_query("value:>=-200").must_include(@apple_duck)
      @john.products.scopes_for_query("value:>=-200").size.must_equal(3)
    end

    describe "spacing" do ###########################
      specify { @john.products.scopes_for_query("value : >= 200").must_include(@tv) }
      specify { @john.products.scopes_for_query("value : >=200").must_include(@tv) }
      specify { @john.products.scopes_for_query("value: >= 200 ").must_include(@tv) }
      specify { @john.products.scopes_for_query("value :>= 200").must_include(@tv) }
      specify { @john.products.scopes_for_query("value:>= 200").must_include(@tv) }
      specify { @john.products.scopes_for_query(" value:>= 200").must_include(@tv) }
      specify { @john.products.scopes_for_query("value: >=200").must_include(@tv) }
    end

  end
  
end
