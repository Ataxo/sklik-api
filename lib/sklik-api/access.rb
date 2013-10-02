# -*- encoding : utf-8 -*-
class SklikApi::Access

  def self.store
    Thread.current[:sklik_api] ||= {}
  end

  #set credentials
  def self.set args = {}
    args.symbolize_keys!
    #check required arguments
    raise ArgumentError, "email is required" unless args[:email]
    raise ArgumentError, "password is required" unless args[:password]
    
    #save argument to right places
    
    store[:args] = args

    #save session if present
    store[:session] = args.has_key?(:session) ? args[:session] : nil

    #return this object!
    return self
  end

  def self.get
    Marshal.load( Marshal.dump ( store[:args] )) 
  end
  
  #return email
  def self.email
    store[:args][:email].to_s
  end

  #for login take first part of email "name@seznam.cz" -> "name"
  def self.login
    store[:args][:email].to_s.split("@").first
  end

  #return customer_id
  def self.customer_id
    store[:args].has_key?(:customer_id) && store[:args][:customer_id] ? store[:args][:customer_id] : nil
  end

  #return password
  def self.password
    store[:args][:password].to_s
  end

  #Set session
  def self.session= session
    store[:session] = session
  end

  #Get session
  def self.session
    store[:session]
  end

  #Has setted session
  def self.session?
    !store[:session].nil?
  end
    
  #if you change Access credentials change uniq identifier -> 
  #used for stroing sessions for multiple logins
  def self.uniq_identifier 
    "#{store[:args][:email]}:#{store[:args][:password]}"
  end
  
  #to prevent changes in settings dump it
  def self.access
    Marshal.load( Marshal.dump( store[:args] ))
  end
  
end

