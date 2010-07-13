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

        subscriber_result = subscribe('/subscribe/42')

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscriber_result.thread_join
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

        subscribe_result = subscribe('/subscribe/42')

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscribe_result.thread_join
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

        subscribe_result = subscribe('/subscribe/42')

        poll_until {
          response = get('/publish/42').response
          response.header['x-channel-subscribers'] == '1'
        }
        delete('/publish/42')

        subscribe_result.thread_join
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
      
      it "should trigger disconnects for open subscriber connections" do
        subscribe_result = subscribe('/subscribe/42')
        delete('/publish/42')
        subscribe_result.thread_join
        
        subscribe_result.response.code.to_i.should == 410
      end
    end
  end
  
  context "POST requests" do
    before(:each) do
      start_server(RedBaton.new)
      put('/publish/42')
    end
    after(:each) do
      stop_server
    end

    specify "The message MUST be immediately delivered to all currently long-held subscriber requests" do
      subscriber_result_1 = subscribe('/subscribe/42')
      subscriber_result_2 = subscribe('/subscribe/42')
      
      post('/publish/42', 'Hi Mom')
      
      subscriber_result_1.thread_join
      subscriber_result_2.thread_join
      
      subscriber_result_1.response.body.should == 'Hi Mom'
      subscriber_result_2.response.body.should == 'Hi Mom'
    end

    specify "MUST be replied to with a 201 Created if there were any long-held subscribers that have been sent this message" do
      subscriber_result = subscribe('/subscribe/42')
      post('/publish/42', 'Hi Mom').response.code.to_i.should == 201
      subscriber_result.thread_join
    end
    
    specify "MUST be replied to with a 202 Accepted if there were no long-held subscribers" do
      post('/publish/42', 'Hi Mom').response.code.to_i.should == 202
    end
    
    context "message storage is configured" do
      xspecify "the message MAY be stored for future retrieval"
      xspecify "the oldest message stored for the channel MAY be deleted"
    end
    
    context "message storage is off" do
      xspecify "messages are not stored for future retrieval"
    end
    
    specify "the Content-Type header of the request MUST be forwarded with the message." do
      subscriber_result = subscribe('/subscribe/42')
      post('/publish/42', 'window.alert("Hi Mom")', {'Content-Type' => 'text/javascript'})
      subscriber_result.thread_join
      subscriber_result.response.header['content-type'].should == 'text/javascript'
    end
    
    xspecify "Message storage limits SHOULD be configurable. publisher locations SHOULD be configurable to allow foregoing message storage on POST requests."
    xspecify "All 200-level responses MUST, in the response body, contain information about the applicable channel. This information MAY contain the number of stored messages and the number of subscribers' requests being long-held prior to this request."
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