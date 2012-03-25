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
        @campaign.save
      end
        
      should "get current status" do
        assert_equal @campaign.args[:status], :running
      end
      
      should "be created with right parameters" do
        campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
        campaign_hash = campaigns.first.to_hash
        assert_equal campaign_hash[:campaign_id], @campaign.args[:campaign_id], "campaign id should be same"
        assert_equal campaign_hash[:status], :running , "campaign should be running"
        assert_equal campaign_hash[:budget].to_f, @test_campaign_hash[:budget].to_f, "budgets should be same"
        assert_equal campaign_hash[:name], @test_campaign_hash[:name], "campaign name should be same"
        assert_equal campaign_hash[:ad_groups].size, @test_campaign_hash[:ad_groups].size, "campaign ad_groups should have same count"
      end
    end
    
  end
end