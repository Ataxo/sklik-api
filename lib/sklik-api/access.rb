# -*- encoding : utf-8 -*-
class SklikApi::Access

  #set credentials
  def self.set args = {}
    args.symbolize_keys!
    #check required arguments
    raise ArgumentError, "email is required" unless args[:email]
    raise ArgumentError, "password is required" unless args[:password]
    
    #save argument to right places
    Thread.current[:sklik_api] ||= {}
    Thread.current[:sklik_api][:args] = args

    #save session if present
    Thread.current[:sklik_api][:session] = args.has_key?(:session) ? args[:session] : nil

    #return this object!
    return self
  end

  def self.get
    Marshal.load( Marshal.dump ( Thread.current[:sklik_api][:args] )) 
  end
  
  #return email
  def self.email
    Thread.current[:sklik_api][:args][:email].to_s
  end

  #for login take first part of email "name@seznam.cz" -> "name"
  def self.login
    Thread.current[:sklik_api][:args][:email].to_s.split("@").first
  end

  #return customer_id
  def self.customer_id
    Thread.current[:sklik_api][:args].has_key?(:customer_id) && Thread.current[:sklik_api][:args][:customer_id] ? Thread.current[:sklik_api][:args][:customer_id] : nil
  end

  #return password
  def self.password
    Thread.current[:sklik_api][:args][:password].to_s
  end

  #Set session
  def self.session= session
    Thread.current[:sklik_api][:session] = session
  end

  #Get session
  def self.session
    Thread.current[:sklik_api][:session]
  end

  #Has setted session
  def self.session?
    !Thread.current[:sklik_api][:session].nil?
  end
    
  #if you change Access credentials change uniq identifier -> 
  #used for stroing sessions for multiple logins
  def self.uniq_identifier 
    "#{Thread.current[:sklik_api][:args][:email]}:#{Thread.current[:sklik_api][:args][:password]}"
  end
  
  #to prevent changes in settings dump it
  def self.access
    Marshal.load( Marshal.dump( Thread.current[:sklik_api][:args] ))
  end
  
end

