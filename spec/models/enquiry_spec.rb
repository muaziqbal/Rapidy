require 'spec_helper'

describe Enquiry, :type => :model do

  before :each do
    Enquiry.all.each { |e| e.destroy }
  end

  describe 'validation' do
    it 'should not create enquiry without criteria' do
      enquiry = create_enquiry_with_created_by('user name', {:enquirer_name => 'Vivek'})
      expect(enquiry).not_to be_valid
      expect(enquiry.errors[:criteria]).to eq(["Please add criteria to your enquiry"])
    end

    it "should not create enquiry with empty criteria" do
      enquiry = create_enquiry_with_created_by('user name', {:enquirer_name => 'Vivek', :criteria => {}})
      expect(enquiry).not_to be_valid
      expect(enquiry.errors[:criteria]).to eq(["Please add criteria to your enquiry"])
    end

    it "should not create enquiry without enquirer_name" do
      enquiry = create_enquiry_with_created_by('user name', {:criteria => {:name => 'Child name'}})
      expect(enquiry).not_to be_valid
      expect(enquiry.errors[:enquirer_name]).to eq(["Please add enquirer name to your enquiry"])
    end

    it "should not create enquiry with empty enquirer name" do
      enquiry = create_enquiry_with_created_by('user name', {:criteria => {:name => ''}})
      expect(enquiry).not_to be_valid
      expect(enquiry.errors[:enquirer_name]).to eq(["Please add enquirer name to your enquiry"])
    end

    describe '#update_from_properties' do
      it "should update the enquiry" do
        enquiry = create_enquiry_with_created_by("jdoe", {:enquirer_name => 'Vivek', :place => 'Kampala'})
        properties = {:enquirer_name => 'DJ', :place => 'Kampala'}

        enquiry.update_from(properties)

        expect(enquiry.enquirer_name).to eq('DJ')
        expect(enquiry['place']).to eq('Kampala')
      end
    end

    describe "new_with_user_name" do
      it "should create a created_by field with the user name and organisation" do
        enquiry = create_enquiry_with_created_by('jdoe', {'some_field' => 'some_value'}, "Jdoe-organisation")
        expect(enquiry['created_by']).to eq('jdoe')
        expect(enquiry['created_organisation']).to eq('Jdoe-organisation')

      end
    end

    describe "timestamp" do
      it "should create a posted_at and created_at fields with the current date" do
        allow(Clock).to receive(:now).and_return(Time.utc(2010, "jan", 22, 14, 05, 0))
        enquiry = create_enquiry_with_created_by('some_user', 'some_field' => 'some_value')
        expect(enquiry['posted_at']).to eq("2010-01-22 14:05:00UTC")
        expect(enquiry['created_at']).to eq("2010-01-22 14:05:00UTC")
      end

      it "should use the supplied created at value" do
        enquiry = create_enquiry_with_created_by('some_user', 'some_field' => 'some_value', 'created_at' => '2010-01-14 14:05:00UTC')
        expect(enquiry['created_at']).to eq("2010-01-14 14:05:00UTC")
      end
    end

    describe "potential_matches" do

      before :each do
        FormSection.all.each(&:destroy)
        form = FormSection.new(:name => "test_form")
        form.fields << Field.new(:name => "name", :type => Field::TEXT_FIELD, :display_name => "name")
        form.fields << Field.new(:name => "location", :type => Field::TEXT_FIELD, :display_name => "location")
        form.fields << Field.new(:name => "gender", :type => Field::TEXT_FIELD, :display_name => "gender")
        form.save!
      end

      after :each do
        FormSection.all.each(&:destroy)
      end

      before :each do
        Child.all.each { |c| c.destroy }
      end


      it "should be an empty array when enquiry is created" do
        enquiry = Enquiry.new(:criteria => {"name" => "Stephen"})
        expect(enquiry.potential_matches).to eq([])
      end

      it "should contain potential matches given one matching child" do
        child = Child.create(:name => "eduardo aquiles", 'created_by' => "me", 'created_organisation' => "stc")
        enquiry = Enquiry.create!(:criteria => {"name " => "eduardo"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches).not_to be_empty
        expect(enquiry.potential_matches).to eq([child.id])
      end

      it "should not fail when enquiry has no potential matches" do
        enquiry = Enquiry.create!(:criteria => {:name => "does not exist"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches).to be_empty
      end

      it "should contain multiple potential matches given multiple matching children" do
        child1 = Child.create(:name => "eduardo aquiles", 'created_by' => "me", 'created_organisation' => "stc")
        child2 = Child.create(:name => "john doe", 'created_by' => "me", :location => "kampala", 'created_organisation' => "stc")
        child3 = Child.create(:name => "foo bar", 'created_by' => "me", :gender => "male", 'created_organisation' => "stc")

        enquiry = Enquiry.create!(:criteria => {:name => "eduardo", :location => "kampala", :gender => "male"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(3)
        expect(enquiry.potential_matches).to include(child1.id, child2.id, child3.id)
      end

      it "should assure that potential_matches contains no duplicates" do
        child1 = Child.create(:name => "eduardo aquiles", :gender => "male", 'created_by' => "me", 'created_organisation' => "stc")
        enquiry = Enquiry.create!(:criteria => {"name" => "eduardo"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(1)
        expect(enquiry.potential_matches).to eq([child1.id])

        enquiry[:criteria].merge!({"gender" => "male"})
        enquiry.save!

        expect(enquiry.potential_matches.size).to eq(1)
        expect(enquiry.potential_matches).to eq([child1.id])
      end

      it "should update potential matches with new matches whenever an enquiry is edited" do
        child1 = Child.create(:name => "eduardo aquiles", 'created_by' => "me", 'created_organisation' => "stc")
        child2 = Child.create(:name => "john doe", 'created_by' => "me", :location => "kampala", 'created_organisation' => "stc")
        child3 = Child.create(:name => "foo bar", 'created_by' => "me", :gender => "male", 'created_organisation' => "stc")

        enquiry = Enquiry.create!(:criteria => {"name" => "eduardo", "location" => "kampala"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(2)
        expect(enquiry.potential_matches).to include(child1.id, child2.id)

        enquiry[:criteria].merge!({"gender" => "male"})
        enquiry.save!

        expect(enquiry.potential_matches.size).to eq(3)
        expect(enquiry.potential_matches).to include(child1.id, child2.id, child3.id)
      end

      it "should remove id that dont match anymore whenever criteria changes" do
        child1 = Child.create(:name => "eduardo aquiles", 'created_by' => "me", 'created_organisation' => "stc")

        enquiry = Enquiry.create!(:criteria => {"name" => "eduardo"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(1)
        expect(enquiry.potential_matches).to eq([child1.id])

        enquiry[:criteria].merge!("name" => "John")
        enquiry.save!

        expect(enquiry.potential_matches.size).to eq(0)
        expect(enquiry.potential_matches).to eq([])
      end

      it "should keep only matching ids when criteria changes" do
        child1 = Child.create(:name => "eduardo aquiles", 'created_by' => "me", 'created_organisation' => "stc")
        child2 = Child.create(:name => "foo bar", :location => "Kampala", 'created_by' => "me", 'created_organisation' => "stc")

        enquiry = Enquiry.create!(:criteria => {"name" => "eduardo", "location" => "Kampala"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(2)
        expect(enquiry.potential_matches).to include(child1.id, child2.id)

        enquiry[:criteria].merge!("name" => "John")
        enquiry.save!

        expect(enquiry.potential_matches.size).to eq(1)
        expect(enquiry.potential_matches).to eq([child2.id])
      end

      it "should sort the results based on solr scores" do
        child1 = Child.create(:name => "Eduardo aquiles", :location => "Kampala", 'created_by' => "me", 'created_organisation' => "stc")
        child2 = Child.create(:name => "Batman", :location => "Kampala", 'created_by' => "not me", 'created_organisation' => "stc")

        enquiry = Enquiry.create!(:criteria => {"name" => "Eduardo", "location" => "Kampala"}, :enquirer_name => "Kisitu")

        expect(enquiry.potential_matches.size).to eq(2)
        expect(enquiry.potential_matches).to eq([child1.id, child2.id])
      end

      describe "match_updated_at" do

        before do
          allow(Clock).to receive(:now).and_return(Time.utc(2013, "jan", 01, 00, 00, 0))
          Child.create(:name => "Eduardo aquiles", :location => "Kyangwali", 'created_by' => "One", 'created_organisation' => "stc")
          Child.create(:name => "Batman", :location => "Kampala", 'created_by' => "Two", 'created_organisation' => "stc")
        end

        after do
          Enquiry.all.each { |enquiry| enquiry.destroy }
          Child.all.each { |child| child.destroy }
        end

        it "should update match_updated_at timestamp when new matching children are found on creation of an Enquiry" do
          enquiry = Enquiry.create!(:criteria => {"name" => "Eduardo", "location" => "Kampala"}, :enquirer_name => "Kisitu")
          expect(enquiry.match_updated_at).to eq(Time.utc(2013, "jan", 01, 00, 00, 0).to_s)
        end

        it "should not update match_updated_at if there are no matching children records on creation of an Enquiry" do
          enquiry = Enquiry.create!(:criteria => {"name" => "Dennis", "location" => "Space"}, :enquirer_name => "Kisitu")
          expect(enquiry.match_updated_at).to eq("")
        end

        it "should update match_updated_at timestamp when new matching children are found on updation of an Enquiry" do

          enquiry = Enquiry.create!(:criteria => {"name" => "Eduardo"}, :enquirer_name => "Kisitu")
          expect(enquiry.match_updated_at).to eq(Time.utc(2013, "jan", 01, 00, 00, 0).to_s)
          expect(enquiry.potential_matches.size).to eq(1)

          allow(Clock).to receive(:now).and_return(Time.utc(2013, "jan", 02, 00, 00, 0).to_s)
          enquiry.criteria.merge!({"location" => "Kampala"})
          enquiry.save!

          expect(enquiry.match_updated_at).to eq(Time.utc(2013, "jan", 02, 00, 00, 0).to_s)
          expect(enquiry.potential_matches.size).to eq(2)
        end
      end
    end

    describe "all_enquires" do
      it "should return a list of all enquiries" do
        save_valid_enquiry('user2', 'enquiry_id' => 'id2', 'criteria' => {'location' => 'Kampala'}, 'enquirer_name' => 'John', 'reporter_details' => {'location' => 'Kampala'})
        save_valid_enquiry('user1', 'enquiry_id' => 'id1', 'criteria' => {'location' => 'Kampala'}, 'enquirer_name' => 'John', 'reporter_details' => {'location' => 'Kampala'})
        expect(Enquiry.all.all.size).to eq(2)
      end
    end

    describe "search_by_match_updated_since" do
      it "should fetch enquiries with match_updated_at time that is at or after timestamp" do
        save_valid_enquiry('user2', 'enquiry_id' => 'id2', 'criteria' => {'location' => 'Kampala'}, 'enquirer_name' => 'John', 'reporter_details' => {'location' => 'Kampala'}, 'match_updated_at' => '2013-09-18 06:42:12UTC')
        save_valid_enquiry('user1', 'enquiry_id' => 'id1', 'criteria' => {'location' => 'Kampala'}, 'enquirer_name' => 'John', 'reporter_details' => {'location' => 'Kampala'}, 'match_updated_at' => '2013-07-18 06:42:12UTC')

        expect(Enquiry.search_by_match_updated_since(DateTime.parse('2013-09-18 05:42:12UTC')).size).to eq(1)
        expect(Enquiry.search_by_match_updated_since(DateTime.parse('2013-09-18 06:42:12UTC')).size).to eq(1)
      end
    end

    private

    def create_enquiry_with_created_by(created_by, options = {}, organisation = "UNICEF")
      user = User.new({:user_name => created_by, :organisation => organisation})
      Enquiry.new_with_user_name(user, options)
    end

    def save_valid_enquiry(user, options = {}, organisation = "UNICEF")
      enquiry = create_enquiry_with_created_by(user, options, organisation)
      enquiry.save!
    end
  end
end
