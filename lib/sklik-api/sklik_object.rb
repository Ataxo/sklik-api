# -*- encoding : utf-8 -*-
class SklikApi
  module Object
    def self.included(base) 
      base.send :extend, ClassMethods         
      base.send :include, InstanceMethods  
    end
    
    module ClassMethods
      
      def connection
        SklikApi::Connection.connection
      end
      
      def find name, id = nil
        if id
          args = ["list#{name.pluralize.camelize}", id]
        else
          args = ["list#{name.pluralize.camelize}"]
        end
        return connection.call(*args) { |param|
          #return list of all objects
          param[name.pluralize.to_sym].collect{|c| c.symbolize_keys }
        }
      end
    end    

    module InstanceMethods
      #get connection for request
      def connection
        SklikApi::Connection.connection
      end

      def initialize args
        @args = args
        return self
      end

      def args
        @args
      end

      def create
        out = connection.call("#{self.class::NAME}.create", *create_args ) { |param|
           param["#{self.class::NAME}Id".to_sym]
        }
        @args["#{self.class.to_s.downcase.split(":").last}_id".to_sym] = out
        @args
      end
            
      def create_args
        raise(NoMethodError, "Please implement 'create_args' method in class: #{self.class} - should return array which will be placed into create method")
      end

      def to_hash
        raise(NoMethodError, "Please implement 'to_hash' method in class: #{self.class} - should return hash which contains all data")
      end
    end
  end
end
