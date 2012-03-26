# -*- encoding : utf-8 -*-
class SklikApi
  class Keyword

    NAME = "keyword"

    include Object
=begin
Example of input hash
{
  :keyword => "\"some funny keyword\""
}
=end
      
    def initialize adgroup, args
      @keyword_data = nil
      #set keyword owner adgroup
      @adgroup = adgroup

      super args
    end
     
    def create_args
      raise ArgumentError, "Keyword need's to know adgroup_id" unless @adgroup.args[:adgroup_id]
      out = []
      #add campaign id to know where to create adgroup
      out << @adgroup.args[:adgroup_id] 
      
      #add adtext struct
      args = {}
      args[:name] = strip_match_type @args[:keyword]
      args[:matchType] = get_math_type @args[:keyword]
      out << args
      
      #return output
      out
    end
    
    def strip_match_type keyword
      keyword.gsub(/(\[|\]|\")/, "")
    end
    
    def get_math_type keyword
      if /^\[.*\]$/  =~ keyword 
        return "exact"
      elsif /^\".*\"$/  =~ keyword 
        return "phrase"
      else
        return "broad"
      end
    end

    def self.apply_math_type keyword, match_type
      return case match_type
      when "broad" then keyword
      when "phrase" then "\"#{keyword}\""
      when "exact" then "[#{keyword}]"
      else keyword
      end
    end
    
    def self.find adgroup, args = {}
       out = []
       super(NAME, adgroup.args[:adgroup_id]).each do |keyword|
         if args[:keyword_id].nil? || (args[:keyword_id] && args[:keyword_id].to_i == keyword[:id].to_i)
           out << SklikApi::Keyword.new( 
             adgroup,
             :keyword_id => keyword[:id],
             :keyword => apply_math_type(keyword[:name], keyword[:matchType] ),
             :status => fix_status(keyword)
           )
         end
       end
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
        @keyword_data = @args[:keyword]
      end
    end
    
    def save 
      if @args[:keyword_id]  #do update
        
      else                    #do save
        #create adtext
        create        
      end
    end 
  end
end
      
