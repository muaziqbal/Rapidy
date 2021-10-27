require 'spec_helper'


describe Child do

  describe "Updating a Child's properties from another Child object" do
    it "replaces existing child properties with non-nil properties from the updated Child" do
      child = Child.new "name" => "Dave", "age" => "28", "origin" => "Croydon", "last_known_location" => "London"
      updated_child = Child.new "name" => "Dave", "age" => "35", "origin" => nil
      child.update_properties_from updated_child
      child['age'].should == "35"
      child['name'].should == "Dave"
      child['origin'].should == "Croydon"
      child['last_known_location'].should == "London"
    end
  end

  describe "validating an existing child record" do
    
    photo = File.new("features/resources/jorge.jpg")
    def photo.content_type
      "image/jpg"
    end

    def photo.original_path
      "features/resources/jorge.jpg"
    end
    
    child = Child.new
    child['last_known_location'] = "location"
    child.photo = photo

    child.save.should == true

    loaded_child = Child.get(child.id)
    loaded_child.save().should == true
  end

  it "should create a unique id based on the last known location and the user name" do
    child = Child.new({'last_known_location'=>'london'})
    UUIDTools::UUID.stub("random_create").and_return(12345)
    child.create_unique_id("george")
    child["unique_identifier"].should == "georgelon12345"
  end

  it "should use a default location if last known location is empty" do
    child = Child.new({'last_known_location'=>nil})
    UUIDTools::UUID.stub("random_create").and_return(12345)
    child.create_unique_id("george")
    child["unique_identifier"].should == "georgexxx12345"
  end


  it "should downcase the last known location of a child before generating the unique id" do
    child = Child.new({'last_known_location'=>'New York'})
    UUIDTools::UUID.stub("random_create").and_return(12345)
    child.create_unique_id("george")
    child["unique_identifier"].should == "georgenew12345"
  end

  it "should append a five digit random number to the unique child id" do
    child = Child.new({'last_known_location'=>'New York'})
    UUIDTools::UUID.stub("random_create").and_return('12345abcd')
    child.create_unique_id("george")
    child["unique_identifier"].should == "georgenew12345"
  end

  it "should handle special characters in last known location when creating unique id" do
    child = Child.new({'last_known_location'=>'��ħķ'})
    UUIDTools::UUID.stub("random_create").and_return('12345abcd')
    child.create_unique_id("george")
    child["unique_identifier"].should == "george���12345"
  end

  describe "history log" do
    it "should not update history on initial creation of child document" do
      child = Child.new('last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
    
      child['histories'].should be_empty
    end
    
    it "should update history with 'from' value on last_known_location update" do
      child = Child.new('last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['last_known_location'] = 'Philadelphia'
      child.save!
    
      changes = child['histories'].first['changes']
      changes['last_known_location']['from'].should == 'New York'
    end
    
    it "should update history with 'to' value on last_known_location update" do
      child = Child.new('last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['last_known_location'] = 'Philadelphia'
      child.save!
    
      changes = child['histories'].first['changes']
      changes['last_known_location']['to'].should == 'Philadelphia'
    end
    
    it "should update history with 'from' value on age update" do
      child = Child.new('age' => '8', 'last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['age'] = '6'
      child.save!
    
      changes = child['histories'].first['changes']
      changes['age']['from'].should == '8'
    end
    
    it "should update history with 'to' value on age update" do
      child = Child.new('age' => '8', 'last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['age'] = '6'
      child.save!
    
      changes = child['histories'].first['changes']
      changes['age']['to'].should == '6'
    end
    
    it "should update history with a combined history record when multiple fields are updated" do
      child = Child.new('age' => '8', 'last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['age'] = '6'
      child['last_known_location'] = 'Philadelphia'
      child.save!
      
      child['histories'].size.should == 1
      changes = child['histories'].first['changes']
      changes['age']['from'].should == '8'
      changes['age']['to'].should == '6'
      changes['last_known_location']['from'].should == 'New York'
      changes['last_known_location']['to'].should == 'Philadelphia'
    end
    
    it "should not record anything in the history if a save occured with no changes" do
      child = Child.new('last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      loaded_child = Child.get(child.id)
      loaded_child.save!
      
      loaded_child['histories'].should be_empty
    end

    it "should update history with the correct date and time when a change has occurred" do
      current_datetime = stub(:strftime => "3/15/2010 04:45")
      Time.stub!(:now).and_return current_datetime
      child = Child.new('last_known_location' => 'New York')
      child.instance_variable_set(:'@file_name', 'some_file.jpg') # to pass photo validation
      child.save!
      
      child['last_known_location'] = 'Philadelphia'
      child.save!
    
      child['histories'].first['datetime'].should == "3/15/2010 04:45"
    end
  end
end
