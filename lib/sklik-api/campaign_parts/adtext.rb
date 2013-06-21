# -*- encoding : utf-8 -*-
class SklikApi
  class Adtext

    NAME = "ad"

    ADDITIONAL_FIELDS = [
      :premiseMode, :premiseID
    ]

    include SklikObject
=begin
Example of input hash
{
  :headline => "Super headline",
  :description1 => "Trying to do ",
  :description2 => "best description ever",
  :display_url => "my_test_url.cz",
  :url => "http://my_test_url.cz"
}


=end

    def initialize args, deprecated_args = {}

      #deprecated way to set up new adgroup!
      if args.is_a?(SklikApi::Adgroup)
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Adtext.new(adgroup, args) to SklikApi::Adtext.new(args = {}) possible to add parent adgroup by adding :adgroup => your adgroup"
        #set adgroup owner campaign
        @adgroup = args
        args = deprecated_args
      #new way to set adgroups!
      else
        #set adgroup owner campaign
        #if in input args there is pointer to parent campaign!
        @adgroup = args.delete(:adgroup)
      end
      @args = args

      @adtext_data = nil

      super args
    end

    def uniq_identifier
      "#{@args[:headline]}#{@args[:description1]}#{@args[:description2]}#{@args[:display_url]}#{@args[:url]}"
    end

    def create_args
      raise ArgumentError, "Adtexts need's to know adgroup_id" unless @args[:adgroup_id] || @adgroup.args[:adgroup_id]
      out = []
      #add campaign id to know where to create adgroup
      out << @args[:adgroup_id] || @adgroup.args[:adgroup_id]

      #add adtext struct
      c_args = {}
      c_args[:creative1] = @args[:headline]
      c_args[:creative2] = @args[:description1]
      c_args[:creative3] = @args[:description2]
      c_args[:clickthruText] = @args[:display_url]
      c_args[:clickthruUrl] = @args[:url]
      c_args[:status] = status_for_update if status_for_update

      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        c_args[add_info] = @args[field_name] if @args[field_name]
      end

      out << c_args

      #return output
      out
    end

    def update_args
      out = []

      #add campaign id on which will be performed update
      out << @args[:adtext_id]

      #prepare campaign struct
      u_args = {}
      u_args[:status] = status_for_update if status_for_update

      out << u_args
      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        u_args[add_info] = @args[field_name] if @args[field_name]
      end

      out
    end

    def self.get id
      if adtext = super(NAME, id)
        SklikApi::Adtext.new(process_sklik_data adtext)
      else
        nil
      end
    end

    def self.find args, deprecated_args = {}
      out = []

      if args.is_a?(Integer)
        return get args

      #asking for adgroup deprecated way!
      elsif args.is_a?(SklikApi::Adgroup)
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Adtext.find(adgroup, args) to SklikApi::Adtext.find(adgroup_id: 1234) possible to add parent adgroup by adding :adgroup => your adgroup"
        adgroup_id = args.args[:adgroup_id]
        args = deprecated_args

      #asking for adgroup by hash with keyword_id
      elsif args.is_a?(Hash) && args[:adtext_id]
        if adtext = get(args[:adtext_id])
          return [adtext]
        else
          return []
        end

      #asking for keyword by hash
      else
        adgroup_id = args[:adgroup_id]
      end

      return [] unless adgroup_id

       super(NAME, adgroup_id).each do |adtext|
         if args[:adtext_id].nil? || (args[:adtext_id] && args[:adtext_id].to_i == adtext[:id].to_i)
           out << SklikApi::Adtext.new(process_sklik_data adtext)
         end
       end
       out
     end

     def self.process_sklik_data adtext = {}
      {
        :adgroup_id => adtext[:groupId],
        :adtext_id => adtext[:id],
        :headline => adtext[:creative1],
        :description1 => adtext[:creative2],
        :description2 => adtext[:creative3],
        :display_url =>adtext[:clickthruText],
        :url => adtext[:clickthruUrl],
        :status => fix_status(adtext)
      }
    end

     def self.fix_status adtext
       if adtext[:removed] == true
         return :stopped
       elsif adtext[:status] == "active"
         return :running
       elsif adtext[:status] == "suspend"
         return :paused
       else
         return :unknown
       end
     end

    def to_hash
      if @adtext_data
        @adtext_data
      else
        @adtext_data = @args
      end
    end

    def self.get_current_status args = {}
      raise ArgumentError, "Adtext_id is required" unless args[:adtext_id]
      if adgroup = self.get(args[:adtext_id])
        adgroup.args[:status]
      else
        raise ArgumentError, "Adtext by #{args.inspect} couldn't be found!"
      end
    end

    def get_current_status
      self.class.get_current_status :adtext_id => @args[:adtext_id]
    end

    def valid?
      clear_errors
      log_error "headline is required or too long" unless args[:headline] && args[:headline].size > 0 && args[:headline].size <= 35
      log_error "description1 is required or too long" unless args[:description1] && args[:description1].size > 0 && args[:description1].size <= 45
      log_error "description2 is required or too long" unless args[:description2] && args[:description2].size > 0 && args[:description2].size <= 45
      log_error "display_url is required or too long" unless args[:display_url] && args[:display_url].size > 0 && args[:display_url].size <= 45
      log_error "url is required" unless args[:url] && args[:url].size > 0 && args[:url].size <= 45
      log_error "adgroup_id is required" unless args[:adgroup_id] || (@adgroup && @adgroup.args[:adgroup_id])
      !errors.any?
    end

    def update args = {}
      @args.merge!(args)
      save
    end

    def save
      clear_errors
      if @args[:adtext_id]  #do update

        #get current status of campaign
        before_status = get_current_status

        #restore campaign before update
        restore if before_status == :stopped

        begin
          update_object

        rescue Exception => e
          log_error e.message
        end

        #remove it if new status is stopped or status doesn't changed and before it was stopped
        remove if (@args[:status] == :stopped) || (@args[:status].nil? && before_status == :stopped)

      else                  #do save
        @args[:adgroup_id] = @adgroup.args[:adgroup_id] if !@args[:adgroup_id] && @adgroup.args[:adgroup_id]

        begin
          #create adtext
          create
        rescue Exception => e
          log_error e.message
          #don't continue with creating campaign!
          return false
        end

        #remove it if new status is stopped
        remove if @args[:status] && @args[:status].to_s.to_sym == :stopped
      end

      !errors.any?
    end

    def log_error message
      @adgroup.log_error "Adtext: #{@args[:headline]} -> #{message}" if @adgroup
      errors << message
    end

  end
end

