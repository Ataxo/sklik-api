# -*- encoding : utf-8 -*-
class SklikApi
  module SklikObject
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods

      def connection
        SklikApi::Connection.connection
      end

      def get name, id
        args = ["#{name}.getAttributes", id]
        return connection.call(*args) { |param|
          param[name.to_sym].symbolize_keys
        }
      rescue SklikApi::NotFound => e
        puts "#{e.class} - #{e.message}"
        return nil
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

      def restore
        begin
          out = connection.call("#{self.class::NAME}.restore", @args["#{self.class.to_s.downcase.split(":").last}_id".to_sym] ) { |param| true }
          #change current status to current!
          @args[:current_stauts] = @args[:status]

          out
        rescue Exception => e
          raise e
        end
      end

      def remove
        out = connection.call("#{self.class::NAME}.remove", @args["#{self.class.to_s.downcase.split(":").last}_id".to_sym] ) { |param| true }

        #change current status!
        @args[:current_stauts] = :stopped

        out
      end

      def create
        out = connection.call("#{self.class::NAME}.create", *create_args ) { |param|
           param["#{self.class::NAME}Id".to_sym]
        }
        @args["#{self.class.to_s.downcase.split(":").last}_id".to_sym] = out
        @args
      end

      def stats= item
        @stats = item
      end

      def stats
        @stats ||= {}
      end

      def get_stats from, to
        @stats ||= connection.call("#{self.class::NAME}.stats", @args["#{self.class.name.to_s.split("::").last.underscore}_id".to_sym], from, to ) { |param|
           {:fulltext => underscore_hash_keys(param[:fulltext]), :context => underscore_hash_keys(param[:context]) }
        }
      end

      def status_for_update
        if @args[:status] == :running
          return "active"
        elsif @args[:status] == :paused
          return "suspend"
        else
          return nil
        end
      end

      def update_object
        out = connection.call("#{self.class::NAME}.setAttributes", *update_args ) { |param| true }

        #if changed status update current status!
        @args[:current_stauts] = @args[:status] if @args[:current_stauts] != @args[:status]

        out
      end

      def create_args
        raise(NoMethodError, "Please implement 'create_args' method in class: #{self.class} - should return array which will be placed into create method")
      end

      def update_args
        raise(NoMethodError, "Please implement 'update_args' method in class: #{self.class} - should return array which will be placed into update method")
      end

      def to_hash
        raise(NoMethodError, "Please implement 'to_hash' method in class: #{self.class} - should return hash which contains all data")
      end

      def underscore_hash_keys hash
        hash.inject({ }) { |x, (k,v)| x[k.underscore.to_sym] = v; x }
      end

      def clear_errors
        @errors = []
      end

      def errors
        @errors ||= []
      end
    end
  end
end
