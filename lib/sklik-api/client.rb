# -*- encoding : utf-8 -*-
class SklikApi
  class Client

    NAME = "client"

    include Object
        
    def initialize args = {}
      super args
    end
    
    def self.find args = {}
      out = connection.call("client.getAttributes") { |param|
        ([param[:user]]|param[:foreignAccounts]).collect{|u| 
          u.symbolize_keys!
          SklikApi::Client.new(
            :customer_id => u[:userId],
            :email => u[:username]
          )
        }
      }
      out.select!{|c| c.args[:customer_id] == args[:customer_id]} if args[:customer_id]
      out.select!{|c| c.args[:email] == args[:email]} if args[:email]
      return out
    end
  end
end
