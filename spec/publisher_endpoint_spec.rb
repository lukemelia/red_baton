require 'spec_helper'

describe "publisher endpoint" do
  context "PUT requests" do
    context "when the specified channel does not exist" do
      before(:each) do
        start_server(RedBaton.new)
        get('/publish/42').code.to_i.should == 404
      end
      after(:each) do
        stop_server
      end
      it "should respond with a 200" do
        response = put('/publish/42')
        response.code.to_i.should == 200
      end
      it "should create the channel" do
        put('/publish/42')
        get('/publish/42').code.to_i.should == 200
      end
    end

    context "when the specified channel exists" do
      before(:each) do
        start_server(RedBaton.new)
        put('/publish/42')
        get('/publish/42').code.to_i.should == 200
      end
      after(:each) do
        stop_server
      end
      it "should respond with a 200" do
        response = put('/publish/42')
        response.code.to_i.should == 200
      end
      it "should leave the existing channel as-is" do
        put('/publish/42')
        get('/publish/42').code.to_i.should == 200
      end
    end
    
  end
  
  context "DELETE requests" do
    context "when the specified channel does not exist" do
      before(:each) do
        start_server(RedBaton.new)
        get('/publish/42').code.to_i.should == 404
      end
      after(:each) do
        stop_server
      end
      it "should respond with a 404" do
        delete('/publish/42').code.to_i.should == 404
      end
    end
    context "when the specified channel exists" do
      before(:each) do
        start_server(RedBaton.new)
        put('/publish/42')
        get('/publish/42').code.to_i.should == 200
      end
      after(:each) do
        stop_server
      end
      it "should respond with a 200" do
        delete('/publish/42').code.to_i.should == 200
      end
      it "should delete the channel" do
        delete('/publish/42')
        get('/publish/42').code.to_i.should == 404
      end
    end
  end
  
  context "other HTTP requests" do
    before(:each) do
      start_server(RedBaton.new)
    end
    after(:each) do
      stop_server
    end
    it "should respond with a 400" do
      send_options_request('/publish/42').code.to_i.should == 400
    end
  end
end