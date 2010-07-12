require 'spec_helper'

describe "subscriber endpoint" do
  
  context "non-GET requests" do
    it "should respond with a 405 Method Not Allowed status code." do
      start_server(RedBaton.new)
      put('/subscribe/42', '').code.to_i.should == 405
      post('/subscribe/42', '').code.to_i.should == 405
      delete('/subscribe/42').code.to_i.should == 405
      stop_server
    end
  end

  context "while waiting for a message" do
    context "when the channel is deleted" do
      it "should return a 410 Gone Response" do
        start_server(RedBaton.new)
        put('/publish/42')
        
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
        
        subscriber_response.code.to_i.should == 410
        
        stop_server
      end
    end
  end
    
end