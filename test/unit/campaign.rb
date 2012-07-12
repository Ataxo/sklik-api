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
        :excluded_search_services => [2,3,4,5,6,7,8], #choose only seznam.cz
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
              "-negative broad keyword",
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
    
    should "return stats" do
      assert_nothing_raised do
        SklikApi::Campaign.find(:campaign_id => 390265).first.get_stats Date.today, Date.today
      end
    end

    should "have hash stored inside" do
      assert_equal @campaign.args, @test_campaign_hash 
    end

    should "return empty array when asking for not known campaign" do
      assert_equal SklikApi::Campaign.find(:campaign_id => 123456789).size , 0
    end
    
    should "return array of search services" do
      assert_equal SklikApi::Campaign.list_search_services, [{:id=>1, :name=>"Vyhledávání na Seznam.cz"},
               {:id=>2, :name=>"Firmy.cz"},
               {:id=>3, :name=>"Sbazar.cz"},
               {:id=>4, :name=>"Encyklopedie.Seznam.cz"},
               {:id=>5, :name=>"Seznam na mobil (Smobil.cz)"},
               {:id=>6, :name=>"Seznam Obrázky (Obrazky.cz)"},
               {:id=>7, :name=>"Seznam Zboží (Zbozi.cz)"},
               {:id=>8, :name=>"Partnerské vyhledávače"}]
    end
    
    context "create" do
      setup do
        @campaign = SklikApi::Campaign.new(@test_campaign_hash)
        unless @campaign.save
          puts "ERROR: \n #{@campaign.errors.join("\n")}"
        end
      end
        
      should "return valid to_hash" do
        campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
        assert_equal campaigns.size, 1, "Find should return array containing one campaign"
        campaign = campaigns.first
        campaign_hash = campaign.to_hash
        assert_equal campaign_hash[:ad_groups].size, @test_campaign_hash[:ad_groups].size, "Campaign should have right adgroup count"
        assert_equal campaign_hash[:ad_groups].inject(0){|i,o| i + o[:keywords].size}, @test_campaign_hash[:ad_groups].inject(0){|i,o| i + o[:keywords].size}, "Campaign should have right keywords count"
        assert_equal campaign_hash[:ad_groups].inject(0){|i,o| i + o[:ads].size}, @test_campaign_hash[:ad_groups].inject(0){|i,o| i + o[:ads].size}, "Campaign should have right ads count"
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