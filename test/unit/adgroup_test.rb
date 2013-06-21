# -*- encoding : utf-8 -*-
require 'helper'
class AdgroupTest < Test::Unit::TestCase
  context "Adgroup" do

    setup do
      @campaign_hash = {
        :name => "Campaign adgroup test - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
        :status => :running,
        :budget => 15.0,
        :cpc => 3.5,
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
          }
        ]
      }

      if @campaign = SklikApi::Campaign.find(@campaign_hash).first
        unless @campaign.update @campaign_hash
          pp @campaign.errors
          raise 'Unable to update campaign!!! Fix this before tesing more'
        end
      else
        @campaign = SklikApi::Campaign.new(@campaign_hash)
        unless @campaign.save
          pp @campaign.errors
          raise 'Unable to Create campaign!!! Fix this before tesing more'
        end
      end
    end

    should "be found in campaign" do
      assert SklikApi::Adgroup.find(campaign_id: @campaign.args[:campaign_id]).size > 0, "In sklik should be some adgroups"
    end

    should "be found/get by id" do
      adgroup = SklikApi::Adgroup.get(7053769)
      assert_not_nil adgroup
      assert adgroup.is_a?(SklikApi::Adgroup), "return SklikApi::Adgroup"

      adgroup = SklikApi::Adgroup.find(adgroup_id: 7053769).first
      assert_not_nil adgroup
      assert adgroup.is_a?(SklikApi::Adgroup), "return SklikApi::Adgroup"

      adgroup = SklikApi::Adgroup.find(campaign_id: 'doesnt matter', adgroup_id: 7053769).first
      assert_not_nil adgroup
      assert adgroup.is_a?(SklikApi::Adgroup), "return SklikApi::Adgroup"
    end

    should "return empty array when asking for not known adgroup" do
      assert_equal SklikApi::Adgroup.find(:campaign_id => @campaign.args[:campaign_id], :name => 'unknown').size , 0
    end

    context "only adgroup" do
      setup do

        @adgroup_hash = {
          :name => "my adgroup name - #{Time.now}",
          :campaign_id => @campaign.args[:campaign_id],
          :cpc => 2.0,
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
        }
        @adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      end

      should "be initialized" do
        assert_nothing_raised do
          SklikApi::Adgroup.new(@adgroup_hash)
        end
      end

      should "be invalid without given campaign_id or campaign" do
        @adgroup_hash.delete(:campaign_id)
        refute SklikApi::Adgroup.new(@adgroup_hash).valid?
      end

      should "be valid with given campaign_id" do
        assert SklikApi::Adgroup.new(@adgroup_hash).valid?
      end

      should "be valid with given campaign" do
        @adgroup_hash.delete(:campaign_id)
        @adgroup_hash[:campaign] = @campaign
        adgroup = SklikApi::Adgroup.new(@adgroup_hash)
        assert adgroup.valid?, "Problem with: #{adgroup.errors}"
      end

      should "use campaign cpc (if no cpc given)" do
        @adgroup_hash.delete(:campaign_id)
        @adgroup_hash.delete(:cpc)
        @adgroup_hash[:campaign] = @campaign
        @campaign.args[:cpc] = @campaign_hash[:cpc]
        adgroup = SklikApi::Adgroup.new(@adgroup_hash)
        assert adgroup.valid?
        assert_equal adgroup.args[:cpc], @campaign_hash[:cpc]
      end

      should "use cpc of adgroup if campaign was given" do
        @adgroup_hash.delete(:campaign_id)
        @adgroup_hash[:campaign] = @campaign
        adgroup = SklikApi::Adgroup.new(@adgroup_hash)
        assert adgroup.valid?
        assert_equal adgroup.args[:cpc], @adgroup_hash[:cpc]
      end

      should "have hash stored inside" do
        assert_equal @adgroup.args, @adgroup_hash
      end
    end
  end
end