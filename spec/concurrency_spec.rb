require 'spec_helper'

describe "concurrency modes" do
  
  describe ":broadcast" do
    before(:each) do
      @red_baton = RedBaton.new(:concurrency => :broadcast)
    end
    
    it "should be the default concurrency type" do
      RedBaton.new.concurrency.should == :broadcast
    end
    
    it "should publish a message to multiple subscribers on a single channel" do
      start_server(@red_baton)
      
      response_1, response_2, response_3 = nil, nil, nil
      
      conn_thread_1 = Thread.new do
        response_1 = get('/subscribe/42')
      end
      
      conn_thread_2 = Thread.new do
        response_2 = get('/subscribe/42')
      end
      
      conn_thread_3 = Thread.new do
        poll_until do
          get('/publish/42').response.header['x-channel-subscribers'] == '2'
        end
        response_3 = post('/publish/42', 'I think I can')
      end
      
      [conn_thread_1, conn_thread_2, conn_thread_3].each &:join

      response_1.code.to_i.should == 200
      response_1.body.should == 'I think I can'
      response_2.code.to_i.should == 200
      response_2.body.should == 'I think I can'
      response_3.code.to_i.should == 201
      
      stop_server
    end
  end
  
  describe ":first" do
    before(:each) do
      @red_baton = RedBaton.new(:concurrency => :first)
    end
    
    it "should publish a message to a channel" do
      start_server(@red_baton)
      
      response_1, response_2 = nil, nil
      conn_thread_1 = Thread.new do
        response_1 = get('/subscribe/42')
      end
      
      response_2 = post('/publish/42', 'I think I can')
      
      conn_thread_1.join

      response_1.code.to_i.should == 200
      response_1.body.should == 'I think I can'
      response_2.code.to_i.should == 201
      
      stop_server
    end
    
    
    it "should close connections on a channel subsequent to the first connection with a 409" do
      start_server(RedBaton.new(:concurrency => :first))
      
      response_1, response_2 = nil, nil
      conn_thread_1 = Thread.new do
        response_1 = get('/subscribe/42')
      end
      conn_thread_2 = Thread.new do
        response_2 = get('/subscribe/42')
      end
      
      conn_thread_2.join
      response_2.code.to_i.should == 409

      stop_server
      conn_thread_1.join
    end    
  end
  
  describe ":last" do
    before(:each) do
      @red_baton = RedBaton.new(:concurrency => :last)
    end
    
    it "should publish a message to a channel" do
      start_server(@red_baton)
      
      response_1, response_2 = nil, nil
      conn_thread_1 = Thread.new do
        response_1 = get('/subscribe/42')
      end
      
      response_2 = post('/publish/42', 'I think I can')
      
      conn_thread_1.join

      response_1.code.to_i.should == 200
      response_1.body.should == 'I think I can'
      response_2.code.to_i.should == 201
      
      stop_server
    end
    
    it "should close the original connection with a 409 when a new connection is opened on the same channel" do
      start_server(@red_baton)
      
      response_1, response_2 = nil, nil
      conn_thread_1 = Thread.new do
        response_1 = get('/subscribe/42')
      end
      conn_thread_2 = Thread.new do
        response_2 = get('/subscribe/42')
      end
      
      conn_thread_1.join
      response_1.should_not be_nil
      response_1.code.to_i.should == 409

      stop_server
      conn_thread_2.join
    end
  end
end