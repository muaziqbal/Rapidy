require 'spec_helper'
describe SystemUsers do

  before :each do
    @sys_user = build :system_users
  end

  after :each do
    @sys_user.destroy
  end

  it "System Users should be valid" do
    @sys_user.should be_valid
    @sys_user.save
  end

  it "should assign _id based on name" do
    @sys_user.save
    @sys_user._id.should == "org.couchdb.user:test_user"
  end

  it "should not save if the username already exists" do
    @sys_user.save
    another_sys_user = build :system_users
    another_sys_user.should_not be_valid
  end

  it "should fetch all the _user documents" do
    @sys_user.save
    SystemUsers.all.length.should == 1
  end
end