# -*- encoding : utf-8 -*-
class SklikApi
  class Adgroup

    NAME = "group"

    include Object
=begin
Example of input hash
{
  :adgroup_id => 1234, #(OPTIONAL) -> when setted it will on save do update of existing adgroup
  :name => "my adgroup name",
  :ads => [ 
    {
      :headline => "Super headline",
      :description1 => "Trying to do ",
      :description2 => "best description ever",
      :display_url => "my_test_url.cz",
      :url => "http://my_test_url.cz"
    }
  ],
  :keywords => [
    "\"some funny keyword\"",
    "[phrase keyword]",
    "broad keyword for me",
    "test of diarcritics âô"
  ]
}


=end
  
    def initialize campaign, args
      @adgroup_data = nil
      #set adgroup owner campaign
      @campaign = campaign

      #initialize adgroups
      @adtexts = []
      if args[:ads] && args[:ads].size > 0
        args[:ads].each do |adtext|
          @adtexts << SklikApi::Adtext.new(self, adtext)
        end
      end
      #initialize adgroups
      @keywords = []
      if args[:keywords] && args[:keywords].size > 0
        args[:keywords].each do |keyword|
          @keywords << SklikApi::Keyword.new(self, :keyword => keyword)
        end
      end
      
      super args
    end
    
    def self.find campaign, args = {}
      out = []
      super(NAME, campaign.args[:campaign_id]).each do |adgroup|
        if args[:adgroup_id].nil? || (args[:adgroup_id] && args[:adgroup_id].to_i == adgroup[:id].to_i)
          out << Adgroup.new( campaign, 
            :adgroup_id => adgroup[:id],
            :cpc => adgroup[:cpc].to_f/100.0, 
            :name => adgroup[:name], 
            :status => fix_status(adgroup)
          )
        end
      end
      out
    end
    
    def self.fix_status adgroup
      if adgroup[:removed] == true
        return :stopped
      else
        return :running
      end
    end
    
    def to_hash
      if @adgroup_data
        @adgroup_data
      else
        @adgroup_data = @args
        @adgroup_data[:ads] = Adtext.find(self).collect{|a| a.to_hash}
        @adgroup_data[:keywords] = Keyword.find(self).collect{|k| k.to_hash}
        @adgroup_data
      end
    end
    
    
    def create_args
      raise ArgumentError, "Adgroup need's to know campaign_id" unless @campaign.args[:campaign_id]
      raise ArgumentError, "Adgroup need's to know campaigns CPC" unless @campaign.args[:cpc]

      out = []
      #add campaign id to know where to create adgroup
      out << @campaign.args[:campaign_id] 
      
      #add adgroup struct
      args = {}
      args[:name] = @args[:name]
      args[:cpc] = (@campaign.args[:cpc] * 100).to_i if @campaign.args[:cpc]
      out << args
      
      #return output
      out
    end
    
    def save 
      if @args[:adgroup_id]  #do update
        
      else                    #do save
        #create adgroup
        create
        
        #create adtexts
        @adtexts.each{ |adtext| adtext.save }
        
        #create keywords
        @keywords.each{ |keyword| keyword.save }
      end
    end

  end
end
      
      