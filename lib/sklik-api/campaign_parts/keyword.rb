# -*- encoding : utf-8 -*-
class SklikApi
  class Keyword

    NAME = "keyword"

    ADDITIONAL_FIELDS = [
      :cpc, :url
    ]
    ADDITIONAL_READ_FIELDS = [
      :disabled, :cpc, :url, :minCpc
    ]

    include SklikObject
=begin
Example of input hash
{
  :keyword => "\"some funny keyword\""
}
=end

    def initialize args, deprecated_args = {}

      #deprecated way to set up new adgroup!
      if args.is_a?(SklikApi::Adgroup)
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Keyword.new(adgroup, args) to SklikApi::Keyword.new(args = {}) possible to add parent adgroup by adding :adgroup => your adgroup"
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

      @keyword_data = nil

      super args
    end

    def create_args
      raise ArgumentError, "Keyword need's to know adgroup_id" unless @args[:adgroup_id] || @adgroup.args[:adgroup_id]
      out = []
      #add campaign id to know where to create adgroup
      out << @args[:adgroup_id] || @adgroup.args[:adgroup_id]

      #add adtext struct
      c_args = {}
      c_args[:name] = strip_match_type @args[:keyword]
      c_args[:matchType] = get_math_type @args[:keyword]
      #Currently not working :(
      c_args[:status] = status_for_update if status_for_update

      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        c_args[add_info] = @args[field_name] if @args[field_name]
      end

      if @args[:cpc]
        c_args[:cpc] = (@args[:cpc] * 100).to_i
      end


      out << c_args

      #return output
      out
    end

    def update_args
      out = []

      #add campaign id on which will be performed update
      out << @args[:keyword_id]

      #prepare campaign struct
      u_args = {}
      u_args[:status] = status_for_update if status_for_update

      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        u_args[add_info] = @args[field_name] if @args[field_name]
      end
      if @args[:cpc]
        u_args[:cpc] = (@args[:cpc] * 100).to_i
      end
      out << u_args

      #return output
      out
    end

    def strip_match_type keyword
      keyword.gsub(/(\[|\]|\")/, "").gsub(/^-/, "")
    end

    def get_math_type keyword
      if /^-\[.*\]$/  =~ keyword
        return "negativeExact"
      elsif /^\[.*\]$/  =~ keyword
        return "exact"
      elsif /^-\".*\"$/  =~ keyword
        return "negativePhrase"
      elsif /^\".*\"$/  =~ keyword
        return "phrase"
      elsif /^-.*$/  =~ keyword
        return "negativeBroad"
      else
        return "broad"
      end
    end

    def self.apply_math_type keyword, match_type
      return case match_type
      when "broad" then keyword
      when "phrase" then "\"#{keyword}\""
      when "exact" then "[#{keyword}]"
      when "negativeBroad" then "-#{keyword}"
      when "negativePhrase" then "-\"#{keyword}\""
      when "negativeExact" then "-[#{keyword}]"
      else keyword
      end
    end

    def self.get id
      if keyword = super(NAME, id)
        SklikApi::Keyword.new(process_sklik_data keyword)
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
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Keyword.find(adgroup, args) to SklikApi::Keyword.find(adgroup_id: 1234) possible to add parent adgroup by adding :adgroup => your adgroup"
        adgroup_id = args.args[:adgroup_id]
        args = deprecated_args

      #asking for adgroup by hash with keyword_id
      elsif args.is_a?(Hash) && args[:keyword_id]
        if keyword = get(args[:keyword_id])
          return [keyword]
        else
          return []
        end

      #asking for keyword by hash
      else
        adgroup_id = args[:adgroup_id]
      end

      return [] unless adgroup_id

      super(NAME, adgroup_id).each do |keyword|
        if args[:keyword_id].nil? || (args[:keyword_id] && args[:keyword_id].to_i == keyword[:id].to_i)
          out << SklikApi::Keyword.new(process_sklik_data keyword)
        end
      end
      out
    end

    def self.process_sklik_data keyword = {}
      out = {
        :adgroup_id => keyword[:groupId],
        :keyword_id => keyword[:id],
        :keyword => apply_math_type(keyword[:name], keyword[:matchType] ),
        :status => fix_status(keyword)
      }
      ADDITIONAL_READ_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        out[field_name] = keyword[add_info] if keyword[add_info]
      end
      out[:cpc] = keyword[:cpc].to_f/100.0 if keyword[:cpc]

      out
    end

    def self.fix_status keyword
      if keyword[:removed] == true
        return :stopped
      elsif keyword[:status] == "active"
        return :running
      elsif keyword[:status] == "suspend"
        return :paused
      elsif keyword[:status] == "nonactive"
        return :paused_by_low_cpc
      else
        return :unknown
      end
    end

    def to_hash
      if @keyword_data
        @keyword_data
      else
        @keyword_data = @args      end
    end


    def self.get_current_status args = {}
      raise ArgumentError, "Keyword_id is required" unless args[:keyword_id]
      if adgroup = self.get(args[:keyword_id])
        adgroup.args[:status]
      else
        raise ArgumentError, "Keyword by #{args.inspect} couldn't be found!"
      end
    end

    def get_current_status
      self.class.get_current_status :keyword_id => @args[:keyword_id]
    end

    def update args = {}
      @args.merge!(args)
      save
    end

    def save
      @args[:adgroup_id] = @adgroup.args[:adgroup_id] if !@args[:adgroup_id] && @adgroup.args[:adgroup_id]

      if @args[:keyword_id]  #do update
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
      else                    #do save
        #create keyword
        begin
          create

        rescue Exception => e
          log_error e.message

          return false
        end

        #remove it if new status is stopped
        remove if @args[:status] && @args[:status].to_s.to_sym == :stopped
      end

      !errors.any?
    end

    def log_error message
      puts message
      @adgroup.log_error "Keyword: #{@args[:keyword]} -> #{message}" if @adgroup
      errors << message
    end

  end
end

