# -*- encoding : utf-8 -*-
class SklikApi
  class Connection
    
    MAX_RETRIES = 3
    DEFAULTS = {
      :debug => false,
      :timeout => 100
    }
    
    def initialize args = {}
      @args = DEFAULTS.merge(args)
    end
    
    def self.connection
      @connection ||= SklikApi::Connection.new(:debug => false)
    end
    
    #prepare connection to sklik
    def connection
      server = XMLRPC::Client.new3(:host => "api.sklik.cz", :path => "/RPC2", :port => 443, :use_ssl => true, :timeout => @args[:timeout])
      server.instance_variable_get(:@http).instance_variable_set(:@verify_mode, OpenSSL::SSL::VERIFY_NONE)
      #fix of UTF-8 encoding
      server.extend(XMLRPCWorkAround)
      #debug mode to see what XMLRPC is doing
      server.set_debug(File.open("log/xmlrpc-#{Time.now.strftime("%Y_%m_%d-%H_%M_%S")}.log","a:UTF-8")) if @args[:debug] 
      
      server
    end
    
    #Get session is method for login into sklik
    #save session for other requests until it expires
    #every taxonomy has its own session!
    def get_session force = false
      @session ||= {}
      if @session.has_key?(SklikApi::Access.uniq_identifier) && !force
        @session[SklikApi::Access.uniq_identifier]
      else
        begin
          param = connection.call("client.login", SklikApi::Access.email, SklikApi::Access.password).symbolize_keys
          if param[:status] == 401
            raise ArgumentError, "Invalid login for: #{SklikApi::Access.email}"
          elsif param[:status] == 200
            return @session[SklikApi::Access.uniq_identifier] = param[:session]
          else
            raise ArgumentError, param[:statusMessage]
          end
        rescue XMLRPC::FaultException => e
          raise ArgumentError, "#{e.faultString}, #{e.faultCode}"
        rescue Exception => e
          raise e
        end
      end
    end
    
    # method to wrap method call to sklik -> allow retry and problem with session expiration
    def call method, *args
      retry_count = MAX_RETRIES
      begin 
        #get response from sklik
        param = connection.call( method, get_session, *args ).symbolize_keys
        if param[:status] == 200
          return yield(param)
        elsif param[:status] == 406
          raise ArgumentError, "Sklik returned: #{method}: #{param[:statusMessage]} #{args.inspect}"
        elsif param[:statusMessage] == "Session has expired or is malformed."
          raise ArgumentError, "session has expired"
        else
          raise ArgumentError, "There is error from sklik #{method}: #{param[:statusMessage]}"
        end
      rescue Exception => e
        retry_count -= 1
        pp "Rescuing from request by: #{e.class} - #{e.message}"
        #if session expired then get new one! and retry
        get_session(true) if e.message == "session has expired"
        #don't retry if there is problem with Invalid paramaters od Data
        retry_count = 0 if e.message.include?("Invalid") 
        retry if retry_count > 0
        raise e
      end
    end
  end
end
