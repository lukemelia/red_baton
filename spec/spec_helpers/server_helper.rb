def start_server(red_baton_app = RedBaton.new, port = 3001)
  if ENV['DEBUG']
    Thin::Logging.debug = true
  else
    Thin::Logging.silent = true
  end
  
  @thin_thread = Thread.new do
    @thin = Thin::Server.new('0.0.0.0', port) do
      run red_baton_app
    end
    @thin.start
  end
  wait_for_server_to_start
end

def stop_server
  @thin.stop!
  @thin_thread.join
end

def wait_for_server_to_start
  $stdout.write "Waiting for server to start" if Thin::Logging.debug?
  server_is_starting = true
  server_start_time = Time.now
  while server_is_starting && (Time.now - server_start_time < 30)
    if Thin::Logging.debug?
      $stdout.write "."
      $stdout.flush
    end
    begin
      if get('/foo').code.to_i == 404
        server_is_starting = false
      end
    rescue
      sleep 5
    end
  end
  if Thin::Logging.debug?
    puts " Ready!"
    $stdout.flush
  end
end

def poll_until(timeout = 30, &block)
  waiting = true
  start_time = Time.now
  while waiting
    if (Time.now - start_time > timeout)
      raise "Timeout expired in wait_for_server_response"
    end
    
    begin
      if yield
        waiting = false
      end
    end
  end
end