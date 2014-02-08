# -*- encoding : utf-8 -*-
require 'helper'
class AdtextIntegrationTest < Test::Unit::TestCase
  context "Integration:Adtext" do

    setup do
      @campaign_hash = {
        :name => "integration adtext - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
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

      @adtext_hash = {
        :adgroup_id => @adgroup.args[:adgroup_id],
        :headline => "Super headline",
        :description1 => "Trying to do",
        :description2 => "best description ever",
        :display_url => "bartas.cz",
        :url => "http://www.bartas.cz/",
        :status => :running,
      }
      @adtext = SklikApi::Adtext.new(@adtext_hash)
      unless @adtext.save
        raise "Unable to continue - Adtext: #{@adtext.errors}"
      end

    end

    def teardown
      @campaign.remove if SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
    end

    should "create paused adtext" do
      @adtext_hash[:headline] += "Paused"
      @adtext_hash[:status] = :paused
      adtext = SklikApi::Adtext.new(@adtext_hash)
      assert adtext.save, "Problem with creating adgroup: #{adtext.errors}"

      assert_equal SklikApi::Adtext.get(adtext.args[:adtext_id]).args[:status], :paused
    end

    should "create stopped adtext" do
      @adtext_hash[:headline] += "Stopped"
      @adtext_hash[:status] = :stopped
      adtext = SklikApi::Adtext.new(@adtext_hash)
      assert adtext.save, "Problem with creating adgroup: #{adtext.errors}"

      assert_equal SklikApi::Adtext.get(adtext.args[:adtext_id]).args[:status], :stopped
    end

    should "find" do
      assert_equal SklikApi::Adtext.find(@adtext.args[:adtext_id]).to_hash.to_a.sort, @adtext_hash.to_a.sort, "By ID"
      assert_equal SklikApi::Adtext.find(adtext_id: @adtext.args[:adtext_id]).first.to_hash.to_a.sort, @adtext_hash.to_a.sort, "By Hash with ID"
    end

    should "get" do
      assert_equal SklikApi::Adtext.get(@adtext.args[:adtext_id]).to_hash.to_a.sort, @adtext_hash.to_a.sort
    end

    should "update" do
      adtext = SklikApi::Adtext.get(@adtext.args[:adtext_id])

      new_attributes = {
        status: :stopped,
      }
      adtext.update new_attributes

      adtext = SklikApi::Adtext.get(@adtext.args[:adtext_id])
      assert_equal adtext.to_hash.to_a.sort, @adtext_hash.merge(new_attributes).to_a.sort, "First update"

      new_attributes = {
        status: :paused,
      }
      adtext.update new_attributes
      adtext = SklikApi::Adtext.get(@adtext.args[:adtext_id])
      assert_equal adtext.to_hash.to_a.sort, @adtext_hash.merge(new_attributes).to_a.sort, "Second update"

    end

  end
end