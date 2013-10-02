# -*- encoding : utf-8 -*-
require 'helper'
class KeywordIntegrationTest < Test::Unit::TestCase
  context "Integration:Keyword" do

    setup do
      @campaign_hash = {
        :name => "integration keyword - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
        :status => :running,
        :budget => 15.0,
        :customer_id => 250497,
        :excluded_search_services => [2,3,4,5,6,7,8], #choose only seznam.cz
        :network_setting => {
          :content => true,
          :search => true
        },
        :ad_groups => []
      }
      @campaign = SklikApi::Campaign.new(@campaign_hash)
      unless @campaign.save
        raise "Unable to continue - Campaign: #{@campaign.errors}"
      end

      @adgroup_hash = {
        :name => "my adgroup name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
        :cpc => 6.0,
        :campaign_id => @campaign.args[:campaign_id],
        :keywords => [],
        :ads => [],
        :status => :running,
      }

      @adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      unless @adgroup.save
        raise "Unable to continue - Adgroup: #{@adgroup.errors}"
      end

      @keyword_hash = {
        :adgroup_id => @adgroup.args[:adgroup_id],
        :keyword => 'testing keyword',
        :status => :running,
      }
      @keyword = SklikApi::Keyword.new(@keyword_hash)
      unless @keyword.save
        raise "Unable to continue - Keyword: #{@keyword.errors}"
      end

    end

    def teardown
      @campaign.remove if SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
    end

    should "create keyword with match type!" do
      keyword_hash = {
        :adgroup_id => @adgroup.args[:adgroup_id],
        :keyword => "[phrase]",
        :status => :running
      }
      keyword = SklikApi::Keyword.new(keyword_hash)
      assert keyword.save, "Problem with creating phrase keyword: #{keyword.errors}"
      assert_equal SklikApi::Keyword.get(keyword.args[:keyword_id]).args[:keyword], keyword_hash[:keyword]

      keyword_hash = {
        :adgroup_id => @adgroup.args[:adgroup_id],
        :keyword => "broad",
        :status => :running
      }
      keyword = SklikApi::Keyword.new(keyword_hash)
      assert keyword.save, "Problem with creating broad keyword: #{keyword.errors}"
      assert_equal SklikApi::Keyword.get(keyword.args[:keyword_id]).args[:keyword], keyword_hash[:keyword]

      keyword_hash = {
        :adgroup_id => @adgroup.args[:adgroup_id],
        :keyword => "\"exact\"",
        :status => :running
      }
      keyword = SklikApi::Keyword.new(keyword_hash)
      assert keyword.save, "Problem with creating exact keyword: #{keyword.errors}"
      assert_equal SklikApi::Keyword.get(keyword.args[:keyword_id]).args[:keyword], keyword_hash[:keyword]

    end
    should "create paused keyword" do
      @keyword_hash[:keyword] += "Paused"
      @keyword_hash[:status] = :paused
      keyword = SklikApi::Keyword.new(@keyword_hash)
      assert keyword.save, "Problem with creating keyword: #{keyword.errors}"

      assert_equal SklikApi::Keyword.get(keyword.args[:keyword_id]).args[:status], :paused
    end

    should "create stopped keyword" do
      @keyword_hash[:keyword] += " stopped"
      @keyword_hash[:status] = :stopped
      keyword = SklikApi::Keyword.new(@keyword_hash)
      assert keyword.save, "Problem with creating keyword: #{keyword.errors}"

      assert_equal SklikApi::Keyword.get(keyword.args[:keyword_id]).args[:status], :stopped
    end

    should "find" do
      assert_equal SklikApi::Keyword.find(@keyword.args[:keyword_id]).to_hash.to_a.sort, @keyword_hash.to_a.sort, "By ID"
      assert_equal SklikApi::Keyword.find(keyword_id: @keyword.args[:keyword_id]).first.to_hash.to_a.sort, @keyword_hash.to_a.sort, "By Hash with ID"
    end

    should "get" do
      assert_equal SklikApi::Keyword.get(@keyword.args[:keyword_id]).to_hash.to_a.sort, @keyword_hash.to_a.sort
    end

    should "update" do
      keyword = SklikApi::Keyword.get(@keyword.args[:keyword_id])

      new_attributes = {
        status: :stopped,
      }
      keyword.update new_attributes

      keyword = SklikApi::Keyword.get(@keyword.args[:keyword_id])
      assert_equal keyword.to_hash.to_a.sort, @keyword_hash.merge(new_attributes).to_a.sort, "First update"

      new_attributes = {
        status: :paused,
      }
      keyword.update new_attributes
      keyword = SklikApi::Keyword.get(@keyword.args[:keyword_id])
      assert_equal keyword.to_hash.to_a.sort, @keyword_hash.merge(new_attributes).to_a.sort, "Second update"

    end

  end
end