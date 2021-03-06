# -*- encoding : utf-8 -*-
require 'helper'
class CampaignTest < Test::Unit::TestCase

  context "Campaign" do

    should "be found" do
      assert SklikApi::Campaign.find(:customer_id => 250497).size > 0, "In sklik sandbox should be some campaigns"
    end

    should "be found without specifying customer_id" do
      assert SklikApi::Campaign.find().size > 0, "In sklik sandbox should be some campaigns"
    end

    should "return empty array when asking for not known campaign" do
      assert_equal SklikApi::Campaign.find(:campaign_id => 123456789).size , 0
    end

    should "return array of search services" do
      assert_equal SklikApi::Campaign.list_search_services, [
         {:id=>1, :name=>"Vyhledávání na Seznam.cz - PC"},
         {:id=>11, :name=>"Vyhledávání na Seznam.cz - Tablet"},
         {:id=>12, :name=>"Vyhledávání na Seznam.cz - Mobil"},
         {:id=>20, :name=>"Vyhledávání na Seznam.cz (nové) - PC"},
         {:id=>21, :name=>"Vyhledávání na Seznam.cz (nové) - Tablet"},
         {:id=>22, :name=>"Vyhledávání na Seznam.cz (nové) - Mobil"},
         {:id=>2, :name=>"Firmy.cz"},
         {:id=>3, :name=>"Sbazar.cz"},
         {:id=>4, :name=>"Encyklopedie.Seznam.cz"},
         {:id=>5, :name=>"Seznam na mobil (Smobil.cz)"},
         {:id=>6, :name=>"Seznam Obrázky (Obrazky.cz)"},
         {:id=>7, :name=>"Seznam Zboží (Zbozi.cz)"},
         {:id=>8, :name=>"Partnerské vyhledávače"}]
    end

    context "only campaign" do
      setup do
        #preserve uniq names of campaigns!
        @only_campaign_hash = {
          :name => "hustokrutě megapřísně - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")} - only",
          :status => :running,
          :budget => 15.0,
          :customer_id => 250497,
          :excluded_search_services => [2,3,4,5,6,7,8], #choose only seznam.cz
          :network_setting => {
            :content => true,
            :search => true
          }
        }
        @campaign = SklikApi::Campaign.new(@only_campaign_hash)
      end

      def teardown
        @campaign.remove if @campaign && @campaign.args[:campaign_id] && SklikApi::Campaign.get(@campaign.args[:campaign_id]) && SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
      end

      should "be initialized" do
        assert_nothing_raised do
          SklikApi::Campaign.new(@only_campaign_hash)
        end
      end

      should "have hash stored inside" do
        assert_equal @campaign.args, @only_campaign_hash
      end

      context "create" do
        setup do
          @campaign = SklikApi::Campaign.new(@only_campaign_hash)
          unless @campaign.save
            puts "ERROR: \n #{@campaign.errors.join("\n")}"
          end
        end

        should "return campaign by get method" do
          campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
          campaign_hash = campaign.to_hash
          assert_equal campaign_hash[:ad_groups].size, 0, "Campaign should have 0 adgroups"
        end

        should "be found/get by id" do
          campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
          assert_not_nil campaign
          assert campaign.is_a?(SklikApi::Campaign), "return SklikApi::Campaign"

          campaign = SklikApi::Campaign.find(campaign_id: @campaign.args[:campaign_id]).first
          assert_not_nil campaign
          assert campaign.is_a?(SklikApi::Campaign), "return SklikApi::Campaign"
        end

        should "return valid to_hash" do
          campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
          assert_equal campaigns.size, 1, "Find should return array containing one campaign"
          campaign = campaigns.first
          campaign_hash = campaign.to_hash
          assert_equal campaign_hash[:ad_groups].size, 0, "Campaign should have 0 adgroups"
        end

        should "be created with right parameters" do
          assert_equal @campaign.args[:status], :running, "Must be running"

          campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
          campaign_hash = campaigns.first.to_hash

          assert_equal campaign_hash[:campaign_id], @campaign.args[:campaign_id], "campaign id should be same"
          assert_equal campaign_hash[:status], :running , "campaign should be running"
          assert_equal campaign_hash[:budget].to_f, @only_campaign_hash[:budget].to_f, "budgets should be same"
          assert_equal campaign_hash[:name], @only_campaign_hash[:name], "campaign name should be same"
          assert_equal campaign_hash[:ad_groups].size, 0, "campaign ad_groups should have 0 adgroups"
        end

        should "be created and updated by changing arguments" do
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          new_name = "Test of updated campaign name- #{Time.now.strftime("%Y.%m.%d %H:%M:%S")} - only"
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
          campaign.save
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :stopped, "campaign should be stopped"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          campaign.args[:status] = :paused
          campaign.save
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :paused, "campaign should be paused"
        end

        should "be created and updated by update method" do
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          new_name = "Test of updated campaign name- #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}"
          assert campaign.update(name: new_name), "Should update name"
          campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
          assert_equal campaign_hash[:name], new_name, "campaign name should be same"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :paused), "should update status to paused"
          campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
          assert_equal campaign_hash[:status], :paused, "campaign should be paused"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :stopped), "should update status to stopped"
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :stopped, "campaign should be stopped"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :paused), "should update status to paused"
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :paused, "campaign should be paused"
        end
      end

    end

    context "full creation" do

      setup do
        @test_campaign_hash = {
          :name => "hustokrutě megapřísně - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
          :status => :running,
          :cpc => 3.5,
          :budget => 15.0,
          :customer_id => 250497,
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

      should "have hash stored inside" do
        assert_equal @campaign.args, @test_campaign_hash
      end

      context "create" do
        setup do
          @campaign = SklikApi::Campaign.new(@test_campaign_hash)
          unless @campaign.save
            puts "ERROR: \n #{@campaign.errors.join("\n")}"
          end
        end

        should "return stats" do
          assert_nothing_raised do
            SklikApi::Campaign.find(@campaign.args[:campaign_id]).get_stats Date.today, Date.today
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

        should "be created with right parameters" do

          assert_equal @campaign.args[:status], :running, "Must be running"

          campaigns = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id])
          campaign_hash = campaigns.first.to_hash

          assert_equal campaign_hash[:campaign_id], @campaign.args[:campaign_id], "campaign id should be same"
          assert_equal campaign_hash[:status], :running , "campaign should be running"
          assert_equal campaign_hash[:budget].to_f, @test_campaign_hash[:budget].to_f, "budgets should be same"
          assert_equal campaign_hash[:name], @test_campaign_hash[:name], "campaign name should be same"
          assert_equal campaign_hash[:ad_groups].size, @test_campaign_hash[:ad_groups].size, "campaign ad_groups should have same count"
        end

        should "be created and updated by changing arguments" do
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
          campaign.save
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :stopped, "campaign should be stopped"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          campaign.args[:status] = :paused
          campaign.save
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :paused, "campaign should be paused"
        end

        should "be created and updated by update method" do
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          new_name = "Test of updated campaign name- #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}"
          assert campaign.update(name: new_name), "Should update name"
          campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
          assert_equal campaign_hash[:name], new_name, "campaign name should be same"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :paused), "should update status to paused"
          campaign_hash = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first.to_hash
          assert_equal campaign_hash[:status], :paused, "campaign should be paused"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :stopped), "should update status to stopped"
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :stopped, "campaign should be stopped"

          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert campaign.update(status: :paused), "should update status to paused"
          campaign = SklikApi::Campaign.find(:customer_id => @campaign.args[:customer_id], :campaign_id => @campaign.args[:campaign_id]).first
          assert_equal campaign.args[:status], :paused, "campaign should be paused"
        end
      end
    end
  end
end