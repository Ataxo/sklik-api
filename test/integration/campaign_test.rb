# -*- encoding : utf-8 -*-
require 'helper'
class CampaignIntegrationTest < Test::Unit::TestCase
  context "Integration:Campaign" do

    setup do
      @only_campaign_hash = {
        :name => "integration campaign - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
        :status => :running,
        :budget => 15.0,
        :customer_id => 192495,
        :excluded_search_services => [2,3,4,5,6,7,8], #choose only seznam.cz
        :network_setting => {
          :content => true,
          :search => true
        },
        :ad_groups => []
      }
      @campaign = SklikApi::Campaign.new(@only_campaign_hash)
      unless @campaign.save
        raise "Unable to continue: #{@campaign.errors}"
      end
    end

    def teardown
      @campaign.remove if @campaign.args[:campaign_id] && SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
    end

    should "create paused campaign" do
      @only_campaign_hash[:name] += "Paused"
      @only_campaign_hash[:status] = :paused
      campaign = SklikApi::Campaign.new(@only_campaign_hash)
      assert campaign.save, "Problem with creating campaing: #{@campaign.errors}"

      assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :paused
    end

    should "create stopped campaign" do
      @only_campaign_hash[:name] += "Stopped"
      @only_campaign_hash[:status] = :stopped
      campaign = SklikApi::Campaign.new(@only_campaign_hash)
      assert campaign.save, "Problem with creating campaing: #{campaign.errors}"

      assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :stopped
    end

    should "remove and restore multiple times" do
      campaign = SklikApi::Campaign.new(@only_campaign_hash)
      assert campaign.save, "Problem with creating campaing: #{campaign.errors}"
      assert_nothing_raised do
        assert SklikApi::Campaign.get(campaign.args[:campaign_id]).remove, "Campaign should be removed"
        assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :stopped, "Campaign should have stopped status"
        assert SklikApi::Campaign.get(campaign.args[:campaign_id]).remove, "Campaign should be removed second time without exception"
        assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :stopped, "Campaign should have stopped status for second time"
        assert SklikApi::Campaign.get(campaign.args[:campaign_id]).restore, "Campaign should be restored"
        assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :running, "Campaign should have running status"
        assert SklikApi::Campaign.get(campaign.args[:campaign_id]).restore, "Campaign should be restored second time without exception"
        assert_equal SklikApi::Campaign.get(campaign.args[:campaign_id]).args[:status], :running, "Campaign should have running status for second time"
      end
    end


    should "find" do
      assert_equal SklikApi::Campaign.find(@campaign.args[:campaign_id]).to_hash.to_a.sort, @only_campaign_hash.to_a.sort
      assert_equal SklikApi::Campaign.find(campaign_id: @campaign.args[:campaign_id]).first.to_hash.to_a.sort, @only_campaign_hash.to_a.sort
    end

    should "get" do
      assert_equal SklikApi::Campaign.get(@campaign.args[:campaign_id]).to_hash.to_a.sort, @only_campaign_hash.to_a.sort
    end

    should "update" do
      campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])

      new_attributes = {
        status: :stopped,
        budget: 12.0,
        :network_setting => {
          :content => false,
          :search => true
        }
      }
      campaign.update new_attributes

      campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
      assert_equal campaign.to_hash.to_a.sort, @only_campaign_hash.merge(new_attributes).to_a.sort, "First update"

      new_attributes = {
        status: :paused,
        budget: 17.0,
        :network_setting => {
          :content => true,
          :search => true
        }
      }
      campaign.update new_attributes
      campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
      assert_equal campaign.to_hash.to_a.sort, @only_campaign_hash.merge(new_attributes).to_a.sort, "Second update"

    end

  end
end