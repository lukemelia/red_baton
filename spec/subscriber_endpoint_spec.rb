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
        
        subscribe_result = subscribe('/subscribe/42')
        delete('/publish/42')
        
        subscribe_result.thread_join
        
        subscribe_result.response.code.to_i.should == 410
        
        stop_server
      end
    end
  end
  
  context "when a message exists" do
    it "should respond with 200 and the message" do
      start_server(RedBaton.new(:store_messages => true))
      post('/publish/42', "Hi, Mom!")
      subscribe_response = get('/subscribe/42')
      subscribe_response.code.to_i.should == 200
      subscribe_response.body.should == "Hi, Mom!"
      stop_server
    end
  end
    
end