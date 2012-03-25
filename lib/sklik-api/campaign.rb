# -*- encoding : utf-8 -*-
class SklikApi
  class Campaign

    NAME = "campaign"

    include Object
=begin
Example of input hash
{
  :campaign_id => 12345, #(OPTIONAL) -> when setted it will on save do update of existing campaign
  :name => "my campaign name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}",
  :status => :running,
  :cpc => 3,
  :budget => 50,

  :network_setting => {
    :content => true,
    :search => true
  },
  
  :ad_groups => [
    {
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
  ]
}
=end
    
    def initialize args
      #variable where are saved current data from system
      @campaign_data = nil
      
      #initialize adgroups
      @adgroups = []
      if args[:ad_groups] && args[:ad_groups].size > 0
        args[:ad_groups].each do |adgroup|
          @adgroups << SklikApi::Adgroup.new(self, adgroup)
        end
      end
      
      @customer_id = args[:customer_id]
      super args
    end
    
    def self.find args = {}
      out = []
      super(NAME, args[:customer_id]).each do |campaign|
        if args[:campaign_id].nil? || (args[:campaign_id] && args[:campaign_id].to_i == campaign[:id].to_i)
          out << Campaign.new( 
            :campaign_id => campaign[:id],
            :budget => campaign[:dayBudget].to_f/100.0, 
            :name => campaign[:name], 
            :status => fix_status(campaign)
          )
        end
      end
      out
    end
    
    def self.fix_status campaign
      if campaign[:removed] == true
        return :stopped
      elsif campaign[:status] == "active"
        return :running
      elsif campaign[:status] == "suspend"
        return :paused
      else
        return :unknown
      end
    end
    
    def to_hash
      if @campaign_data
        @campaign_data
      else
        @campaign_data = @args
        @campaign_data[:ad_groups] = Adgroup.find(self).collect{|a| a.to_hash}
        @campaign_data
      end
    end
    
    def create_args
      out = []
      
      #prepare campaign struct
      args = {}
      args[:name] = @args[:name]
      args[:dayBudget] = (@args[:budget] * 100).to_i if @args[:budget]
      args[:context] = @args[:network_setting][:context] ||= true if @args[:network_setting]
      out << args
      
      #add customer id on which account campaign should be created
      out << @customer_id if @customer_id
      pp @customer_id
      pp out
      out
    end

    def save 
      if @args[:campaign_id]  #do update
        
      else                    #do save
        #create campaign
        create
        
        #create adgroups
        @adgroups.each{ |adgroup| adgroup.save }
        
        @campaign_data = @args
      end
    end
  end
end

#include campaign parts
["keyword", "adtext", "adgroup"].each { |file| require File.join(File.dirname(__FILE__), "campaign_parts/#{file}.rb") }
