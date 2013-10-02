# -*- encoding : utf-8 -*-
class SklikApi
  class Connection

    MAX_RETRIES = 3
    DEFAULTS = {
      :debug => false,
      :timeout => 100
    }

    #prepare connection to sklik
    def self.connection
      Thread.current[:sklik_api] ||= {}
      unless Thread.current[:sklik_api][:connection]
        path = (SklikApi.use_sandbox_for_test? && (ENV['RACK_ENV'] || ENV['RAILS'] == "test")) ? "/sandbox/RPC2" : "/RPC2"
        server = XMLRPC::Client.new3(:host => "api.sklik.cz", :path => path, :port => 443, :use_ssl => true, :timeout => @args[:timeout])
        server.instance_variable_get(:@http).instance_variable_set(:@verify_mode, OpenSSL::SSL::VERIFY_NONE)
        #fix of UTF-8 encoding
        server.extend(XMLRPCWorkAround)
        #debug mode to see what XMLRPC is doing
        server.set_debug(File.open("log/xmlrpc-#{Time.now.strftime("%Y_%m_%d-%H_%M_%S")}.log","a:UTF-8")) if @args[:debug]
        Thread.current[:sklik_api][:connection] = server
      end
      Thread.current[:sklik_api][:connection]
    end

    def reopen_connection!
      Thread.current[:sklik_api] ||= {}
      Thread.current[:sklik_api][:connection] = nil
      connection
    end

    def initialize args = {}
      @args = DEFAULTS.merge(args)
    end

    def self.connection
      @connection ||= SklikApi::Connection.new(:debug => false)
    end

    #prepare connection to sklik
    def connection
      self.class.connection
    end

    #prepare connection to sklik
    def reopen_connection!
      self.class.reopen_connection!
    end

    def set_new_session response
      Thread.current[:sklik_api][:sessions] ||= {}
      if response.has_key?(:session)
        Thread.current[:sklik_api][:sessions][SklikApi::Access.uniq_identifier] = response[:session]
        SklikApi::Access.session = response[:session]
      end
    end

    #Get session is method for login into sklik
    #save session for other requests until it expires
    #every taxonomy has its own session!
    def get_session force = false
      Thread.current[:sklik_api][:sessions] ||= {}
      #try to get session from cache
      if Thread.current[:sklik_api][:sessions].has_key?(SklikApi::Access.uniq_identifier) && !force
        Thread.current[:sklik_api][:sessions][SklikApi::Access.uniq_identifier]

      #try to use session from Access settings
      elsif SklikApi::Access.session? && !force
        return Thread.current[:sklik_api][:sessions][SklikApi::Access.uniq_identifier] = SklikApi::Access.session

      #else retrive new session
      else
        begin
          SklikApi.log(:debug, "Getting session for #{SklikApi::Access.email}")
          param = connection.call("client.login", SklikApi::Access.email, SklikApi::Access.password).symbolize_keys
          SklikApi.log(:debug, "Session received: #{param.inspect}")

          #good session
          if param[:status] == 200
            #SET NEW SESSION
            SklikApi::Access.session = param[:session]
            return Thread.current[:sklik_api][:sessions][SklikApi::Access.uniq_identifier] = param[:session]

          #bad login
          elsif param[:status] == 401
            raise ArgumentError, "Invalid login for: #{SklikApi::Access.email}"

          #Something else went wrong
          else
            raise ArgumentError, param[:statusMessage]
          end

        rescue XMLRPC::FaultException => e
          raise ArgumentError, "#{e.faultString}, #{e.faultCode}"
        rescue Exception => e
          #when closed IO -> retry
          if e.class.name =~ /IOError/
            reopen_connection!
            retry
          end

          raise e
        end
      end
    end

    # method to wrap method call to sklik -> allow retry and problem with session expiration
    def call method, *args

      SklikApi.log(:debug, "Calling api: #{method} [#{args}]") unless method == "client.login"
      retry_count = MAX_RETRIES
      begin
        #get response from sklik
        param = connection.call( method, get_session, *args ).symbolize_keys
        SklikApi.log(:debug, "Response from api: #{param.inspect}") unless method == "client.login"

        # save session from new call - if present
        set_new_session param

        if [200].include?(param[:status])
          return yield(param)
        elsif param[:status] == 204 #Already removed
          SklikApi.log(:info, "Trying to #{method} of #{args.inspect} but object is already in this status")
          return true
        elsif param[:status] == 400
          raise SklikApi::InvalidArguments, "Calling method: #{method} with invalid arguments: #{args}, #{param.inspect}"
        elsif param[:status] == 404
          raise SklikApi::NotFound, "Calling method: #{method} with params: #{args} was not found"
        elsif param[:status] == 406
          raise SklikApi::InvalidData, print_errors(param[:errors])
        elsif param[:statusMessage] == "Session has expired or is malformed."
          raise ArgumentError, "session has expired"
        else
          raise ArgumentError, "There is error from sklik #{method}: #{param.inspect}: #{args.inspect}"
        end
      rescue Exception => e

        #when closed IO -> retry
        if e.class.name =~ /IOError/
          reopen_connection!
          retry
        end
        #when know exception which is not fault of sklik don't retry!
        raise e if e.class.name =~ /SklikApi::/

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

    def print_errors error_hash
      error_hash.collect do |one_error|
        out = "#{one_error.delete("id").humanize} ("
        out += one_error.to_a.collect do |key, value|
          "#{key} = #{value}"
        end.join(", ")
        out + ")"
      end.join("; ")
    end
  end
end
