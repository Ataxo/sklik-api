# -*- encoding : utf-8 -*-
require 'helper'
class CampaignTest < Test::Unit::TestCase
  context "Campaign" do
    
    setup do
      @test_campaign_hash = {
        :name => "hustokrutě megapřísně - #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}",
        :status => :running,
        :cpc => 3.5,
        :budget => 15.0,
        :customer_id => 192495,

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
                :display_url => "bartas.cz",
                :url => "http://www.bartas.cz"
              }
            ],
            :keywords => [
              "\"some funny keyword\"",
              "[myphrase keyword]",
              "mybroad keyword for me",
              "test of diarcritics âô"
            ]
          },
          {
            :name => "hustokrutě mazácká adgroupa",
            :ads => [ 
              {
                :headline => "Super bombasitcký",
                :description1 => "Trying to do ",
                :description2 => "best description ever",
                :display_url => "bartas.cz",
                :url => "http://www.bartas.cz?utm_adgroup=4"
              }
            ],
            :keywords => [
              "\"some funny keyword\"",
              "[myphrase keyword]",
              "mybroad keyword for me",
              "test of diarcritics âô",
              "dokonalý kw"
            ]
          }
        ]
      }
      @campaign = SklikApi::Campaign.new(@test_campaign_hash)
    end 
    
    should "be initialized" do
      assert_nothing_raised do
        SklikApi::Campaign.new(@test_campaign_hash)
      end  
    end
    
    should "be found" do 
      assert_equal SklikApi::Campaign.find(:campaign_id => 390265).size, 1
      assert SklikApi::Campaign.find(:customer_id => 192495).size > 0
    end
    
    should "have hash stored inside" do
      assert_equal @campaign.args, @test_campaign_hash 
    end

    should "return empty array when asking for not known campaign" do
      assert_equal SklikApi::Campaign.find(:campaign_id => 123456789).size , 0
    end
    
    context "create" do
      setup do
        @campaign = SklikApi::Campaign.new(@test_campaign_hash)
        unless @campaign.save
          puts "ERROR: \n #{@campaign.errors.join("\n")}"
        end
      end
        
      should "be created with right parameters and updated" do
        
        assert_equal @campaign.args[:status], :running, "Must be running"
        
        campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
        campaign_hash = campaigns.first.to_hash
        assert_equal campaign_hash[:campaign_id], @campaign.args[:campaign_id], "campaign id should be same"
        assert_equal campaign_hash[:status], :running , "campaign should be running"
        assert_equal campaign_hash[:budget].to_f, @test_campaign_hash[:budget].to_f, "budgets should be same"
        assert_equal campaign_hash[:name], @test_campaign_hash[:name], "campaign name should be same"
        assert_equal campaign_hash[:ad_groups].size, @test_campaign_hash[:ad_groups].size, "campaign ad_groups should have same count"
        
        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        new_name = "Test of updated campaign name- #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}"
        campaign.args[:name] = new_name
        campaign.save
        campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
        assert_equal campaign_hash[:name], new_name, "campaign name should be same"
        
        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        campaign.args[:status] = :paused
        campaign.save
        campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
        assert_equal campaign_hash[:status], :paused, "campaign should be paused"
        
        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        campaign.args[:status] = :stopped
        puts "STOPPINGGGGGG"
        campaign.save
        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        assert_equal campaign.args[:status], :stopped, "campaign should be stopped"

        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        campaign.args[:status] = :paused
        puts "PAUSINGGGGGGG"
        campaign.save
        campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
        assert_equal campaign.args[:status], :paused, "campaign should be paused"

      end
    end
  end
end