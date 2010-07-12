require 'spec_helper'

describe "publisher endpoint" do
  context "GET requests" do
    context "when the specified channel does not exist" do
      before(:each) do
        start_server(RedBaton.new)
      end
      after(:each) do
        stop_server
      end
      it "should respond with 404" do
        get('/publish/42').code.to_i.should == 404
      end
    end
    context "when the specified channel exists" do
      before(:each) do
        start_server(RedBaton.new)
        put('/publish/42')
      end
      after(:each) do
        stop_server
      end

      it "should respond with 200" do
        get('/publish/42').code.to_i.should == 200
      end

      it "should include the number of subscribers in an X-Channel-Subscribers header" do
        get('/publish/42').header['x-channel-subscribers'].should == '0'

        subscriber_response = nil
        subscriber_thread = Thread.new do
          subscriber_response = get('/subscribe/42')
        end

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscriber_thread.join
      end
      
      it "should include the number of messages in an X-Channel-Messages header" do
        get('/publish/42').header['x-channel-messages'].should == '0'
        post('/publish/42', 'Hi Mom')
        get('/publish/42').header['x-channel-messages'].should == '1'
        post('/publish/42', 'Hi Dad')
        get('/publish/42').header['x-channel-messages'].should == '2'
      end
    end
  end
  
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
      
      it "should include the number of subscribers in an X-Channel-Subscribers header" do
        put('/publish/42').header['x-channel-subscribers'].should == '0'

        subscriber_response = nil
        subscriber_thread = Thread.new do
          subscriber_response = get('/subscribe/42')
        end

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscriber_thread.join
      end
      
      it "should include the number of messages in an X-Channel-Messages header" do
        put('/publish/42').header['x-channel-messages'].should == '0'
        post('/publish/42', 'Hi Mom')
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
      
      it "should include the number of subscribers in an X-Channel-Subscribers header" do
        put('/publish/42').header['x-channel-subscribers'].should == '0'

        subscriber_response = nil
        subscriber_thread = Thread.new do
          subscriber_response = get('/subscribe/42')
        end

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscriber_thread.join
      end
      
      it "should include the number of messages in an X-Channel-Messages header" do
        put('/publish/42').header['x-channel-messages'].should == '0'
        post('/publish/42', 'Hi Mom')
        put('/publish/42').header['x-channel-messages'].should == '1'
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
      
      it "should include the number of subscribers in an X-Channel-Subscribers header" do
        delete('/publish/42').header['x-channel-subscribers'].should == '0'
      end
      
      it "should include the number of messages in an X-Channel-Messages header" do
        delete('/publish/42').header['x-channel-messages'].should == '0'
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