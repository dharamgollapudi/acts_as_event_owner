require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsEventOwner::Core do
  before(:each) do
    clean_database!
    @user = User.create :name => 'dude'
    Time.zone = 'Eastern Time (US & Canada)'
    @now = Time.zone.now
    @bod = Date.today.to_time.in_time_zone
  end

  it "adds associations to the host object" do
    lambda {
      @user.events
      @user.event_specifications
    }.should_not raise_error
  end

  it "adds event specifications to the host object" do
    lambda {
      @user.event_specifications.create :description => 'walk the dog', :start_at => @now, :repeat => :daily, :frequency => 1
    }.should change(EventSpecification, :count).by(1)

    specs = @user.reload.event_specifications
    specs.size.should == 1
  end

  it "adds events to the host object" do
    @user.event_specifications.create :description => 'walk the dog', :start_at => @now, :repeat => :daily, :frequency => 1, :generate => false
    @user.event_specifications.create :description => 'go to the gym', :start_at => @now, :repeat => :daily, :frequency => 2, :generate => false

    lambda {
      @user.events.generate :from => @bod, :to => @bod + 1.week
    }.should change(EventOccurrence, :count).by(11)
  end

  it "injects events into the association immediately" do
    @user.event_specifications.create :description => 'walk the dog', :start_at => @now, :repeat => :daily, :frequency => 1, :generate => false
    @user.events.should be_empty
    @user.events.generate :from => @bod, :to => @bod + 1.week
    @user.events.should be_present
    @user.events.size.should == 7
  end

  describe "events association" do
    before(:each) do
      @new_event = EventOccurrence.new
      @new_event.should be_valid
    end

    it "raises an exception if #<< is called" do
      lambda { @user.events << @new_event }.should raise_error(ActsAsEventOwner::Exception)
    end

    it "raises an exception is #build is called" do
      lambda { @user.events.build @new_event.attributes }.should raise_error(ActsAsEventOwner::Exception)
    end

    it "raises an exception if #create is called" do
      lambda { @user.events.create @new_event.attributes }.should raise_error(ActsAsEventOwner::Exception)
    end

    describe "extensions" do
      before(:each) do
        @user.event_specifications.create :description => 'walk the dog', :start_at => @bod - 7.days, :repeat => :daily, :frequency => 1
        @user.events.length.should == 30
      end

      it "provides an extension for upcoming events" do
        @user.events.upcoming.length.should == 22
      end

      it "provides an extension for past events" do
        @user.events.past.length.should == 8
      end
    end
  end
end