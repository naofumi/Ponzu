require 'test_helper'

class SimpleSerializerTest < ActiveSupport::TestCase
  class TestClass
    include SimpleSerializer
    serialize_array :test_attribute

    # mock ActiveRecord::Base
    def read_attribute(attr_name)
      @test_attribute
    end
    # mock ActiveRecord::Base
    def write_attribute(attr_name, value)
      @test_attribute = value
    end
  end

  def setup
    @test_obj = TestClass.new 
  end

  test "should store values as JSON string" do
    @test_obj.test_attribute = []
    assert_equal "[]", @test_obj.read_attribute(:test_attribute)
  end

  test "should return an array if database value is null" do
    @test_obj.write_attribute(:test_attribute, nil)
    assert_equal [], @test_obj.test_attribute
  end

  test "should return an array if database value is empty string" do
    @test_obj.write_attribute(:test_attribute, "")
    assert_equal "", @test_obj.read_attribute(:test_attribute)
    assert_equal [], @test_obj.test_attribute
  end

  test "should store complex values as escaped JSON string" do
    @test_obj.test_attribute = [:hello => {:me => :to}]
    assert_equal "[{\"hello\":{\"me\":\"to\"}}]", @test_obj.read_attribute(:test_attribute)
  end

end

class SimpleSerializerTestWithObjectReconstruction < ActiveSupport::TestCase
  class TestObject
    attr_accessor :name, :address
    def initialize(options)
      options.symbolize_keys!
      @name = options[:name]
      @address = options[:address]
    end
  end

  class TestClassWithObjectElements
    include SimpleSerializer
    serialize_array :test_attribute, :class => "SimpleSerializerTestWithObjectReconstruction::TestObject"

    # mock ActiveRecord::Base
    def read_attribute(attr_name)
      @test_attribute
    end
    # mock ActiveRecord::Base
    def write_attribute(attr_name, value)
      @test_attribute = value
    end
  end

  def setup
    @test_obj_with_object_elements = TestClassWithObjectElements.new    
  end

  test "should work with complex objects as elements" do
    @test_obj_with_object_elements.test_attribute = [TestObject.new(:name => "name_1", :address => "address_1"), 
                                                     TestObject.new(:name => "name_2", :address => "address_2")]
    assert_equal "[{\"name\":\"name_1\",\"address\":\"address_1\"},{\"name\":\"name_2\",\"address\":\"address_2\"}]", 
                 @test_obj_with_object_elements.read_attribute(:test_attribute)
    assert_equal TestObject.new(:name => "name_1", :address => "address_1").name, 
                 @test_obj_with_object_elements.test_attribute.first.name
  end
end

class SimpleSerializerTestWithTypecaster < ActiveSupport::TestCase
  class TestClass
    include SimpleSerializer
    serialize_array :test_attribute, :typecaster => :typecast_to_integers

    # mock ActiveRecord::Base
    def read_attribute(attr_name)
      @test_attribute
    end
    # mock ActiveRecord::Base
    def write_attribute(attr_name, value)
      @test_attribute = value
    end

    def typecast_to_integers(array)
      array.map{|a| a.to_i}
    end
  end

  def setup
    @test_obj = TestClass.new 
  end

  test "should typecast before serializing" do
    @test_obj.test_attribute = ["1", "2", "3"]
    assert_equal "[1,2,3]", @test_obj.read_attribute(:test_attribute)

    @test_obj.test_attribute = [1, 2, 3]
    assert_equal "[1,2,3]", @test_obj.read_attribute(:test_attribute)

    @test_obj.test_attribute = ["1-man", "2-monkeys", "3-mice"]
    assert_equal "[1,2,3]", @test_obj.read_attribute(:test_attribute)
  end
end

class SimpleSerializerTestOnNonArray < ActiveSupport::TestCase
  class TestClass
    include SimpleSerializer
    serialize_single :test_attribute
        # mock ActiveRecord::Base
    def read_attribute(attr_name)
      @test_attribute
    end
    # mock ActiveRecord::Base
    def write_attribute(attr_name, value)
      @test_attribute = value
    end
  end

  def setup
    @test_obj = TestClass.new 
  end

  test "should store values as JSON string" do
    @test_obj.test_attribute = {}
    assert_equal "[{}]", @test_obj.read_attribute(:test_attribute)
  end

  test "should return nil if database value is null" do
    @test_obj.write_attribute(:test_attribute, nil)
    assert_equal nil, @test_obj.test_attribute
  end

  test "should return nil if database value is empty string" do
    @test_obj.write_attribute(:test_attribute, "")
    assert_equal "", @test_obj.read_attribute(:test_attribute)
    assert_equal nil, @test_obj.test_attribute
  end

  test "should store complex values as escaped JSON string" do
    @test_obj.test_attribute = {:hello => {:me => :to}}
    assert_equal "[{\"hello\":{\"me\":\"to\"}}]", @test_obj.read_attribute(:test_attribute)
  end

  test "should store and retrive simple hashes" do
    @test_obj.test_attribute = {}
    assert_equal({}, @test_obj.test_attribute)
    @test_obj.test_attribute = {:my => 'name'}
    assert_equal({'my' => 'name'}, @test_obj.test_attribute)

  end
end