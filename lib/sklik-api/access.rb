# -*- encoding : utf-8 -*-
class SklikApi::Access

  #set credentials
  def self.set args = {}
    args.symbolize_keys!
    #check required arguments
    raise ArgumentError, "email is required" unless args[:email]
    raise ArgumentError, "password is required" unless args[:password]
    
    #save argument to right places
    @args = args
    
    #return this object!
    return self
  end

  def self.get
    Marshal.load( Marshal.dump (@args )) 
  end
  
  #return email
  def self.email
    @args[:email].to_s
  end

  #for login take first part of email "name@seznam.cz" -> "name"
  def self.login
    @args[:email].to_s.split("@").first
  end

  #return customer_id
  def self.customer_id    
    @args.has_key?(:customer_id) && @args[:customer_id] ? @args[:customer_id] : nil
  end

  #return password
  def self.password
    @args[:password].to_s
  end
    
  #if you change Access credentials change uniq identifier -> 
  #used for stroing sessions for multiple logins
  def self.uniq_identifier 
    "#{@args[:email]}:#{@args[:password]}"
  end
  
  #to prevent changes in settings dump it
  def self.access
    Marshal.load( Marshal.dump( @args ))
  end
  
end

