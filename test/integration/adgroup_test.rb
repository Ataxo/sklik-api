# -*- encoding : utf-8 -*-
require 'helper'
class AdgroupIntegrationTest < Test::Unit::TestCase
  context "Integration:Adgroup" do

    setup do
      @campaign_hash = {
        :name => "integration adgroup - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
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
        :ads => [
          {
            :headline => "Super headline",
            :description1 => "Trying to do",
            :description2 => "best description ever",
            :display_url => "bartas.cz",
            :url => "http://www.bartas.cz/",
            :status => :running,
          }
        ],
        :status => :running,
      }

      @adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      unless @adgroup.save
        raise "Unable to continue - Adgroup: #{@adgroup.errors}"
      end
    end

    def teardown
      @campaign.remove if SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
    end

    should "create paused adgroup" do
      @adgroup_hash[:name] += "Paused"
      @adgroup_hash[:status] = :paused
      adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      assert adgroup.save, "Problem with creating adgroup: #{adgroup.errors}"

      assert_equal SklikApi::Adgroup.get(adgroup.args[:adgroup_id]).args[:status], :paused
    end

    should "create stopped adgroup" do
      @adgroup_hash[:name] += "Stopped"
      @adgroup_hash[:status] = :stopped
      adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      assert adgroup.save, "Problem with creating adgroup: #{@adgroup.errors}"

      assert_equal SklikApi::Adgroup.get(adgroup.args[:adgroup_id]).args[:status], :stopped
    end

    should "find" do
      assert_equal SklikApi::Adgroup.find(@adgroup.args[:adgroup_id]).to_hash.to_a.sort, @adgroup_hash.to_a.sort
      assert_equal SklikApi::Adgroup.find(adgroup_id: @adgroup.args[:adgroup_id]).first.to_hash.to_a.sort, @adgroup_hash.to_a.sort
    end

    should "get" do
      assert_equal SklikApi::Adgroup.get(@adgroup.args[:adgroup_id]).to_hash.to_a.sort, @adgroup_hash.to_a.sort
    end

    should "update" do
      adgroup = SklikApi::Adgroup.get(@adgroup.args[:adgroup_id])

      new_attributes = {
        name: adgroup.args[:name] + " T1",
        status: :stopped,
        cpc: 5.0,
      }
      adgroup.update new_attributes

      adgroup = SklikApi::Adgroup.get(@adgroup.args[:adgroup_id])
      assert_equal adgroup.to_hash.to_a.sort, @adgroup_hash.merge(new_attributes).to_a.sort, "First update"

      new_attributes = {
        name: adgroup.args[:name] + " T2",
        status: :paused,
        cpc: 8.0,
      }
      adgroup.update new_attributes
      adgroup = SklikApi::Adgroup.get(@adgroup.args[:adgroup_id])
      assert_equal adgroup.to_hash.to_a.sort, @adgroup_hash.merge(new_attributes).to_a.sort, "Second update"

    end

    should "create adgroup with specified KW" do
      adgroup_hash = {
        :name => "my adgroup name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")} - Testing KW",
        :cpc => 6.0,
        :campaign_id => @campaign.args[:campaign_id],
        :keywords => [
          { :keyword => "[super kw]", :url => 'http://super.bartas.cz/', :cpc => 3.0},
          { :keyword => "\"other kw\"", :url => 'http://mega.bartas.cz/', :cpc => 9.1}
        ],
        :ads => [],
        :status => :running,
      }

      adgroup = SklikApi::Adgroup.new(adgroup_hash)
      assert adgroup.save, "Should be saved but got: #{adgroup.errors}"


      adgroup = SklikApi::Adgroup.get(adgroup.args[:adgroup_id])
      returned_hash = adgroup.to_hash

      returned_hash[:keywords].each do |kw|
        kw.delete(:keyword_id)
        kw.delete(:adgroup_id)
        kw.delete(:status)
      end

      returned_hash[:keywords] = returned_hash[:keywords].to_a.collect{|h|h.to_a.sort}.sort
      adgroup_hash[:keywords] = adgroup_hash[:keywords].to_a.collect{|h|h.to_a.sort}.sort
      assert_equal returned_hash.to_a.sort, adgroup_hash.to_a.sort
    end

    should "update adgroup with specified Ads" do
      adgroup_hash = {
        :name => "my adgroup name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")} - Testing ADS",
        :cpc => 6.0,
        :campaign_id => @campaign.args[:campaign_id],
        :keywords => [
          { :keyword => "[super kw]", :url => 'http://super.bartas.cz/', :cpc => 3.0},
          { :keyword => "\"other kw\"", :url => 'http://mega.bartas.cz/', :cpc => 9.1}
        ],
        :ads => [
          {
            :headline => "Super headline",
            :description1 => "Trying to do",
            :description2 => "best description ever",
            :display_url => "bartas.cz",
            :url => "http://www.bartas.cz/?updated_url",
            :status => :paused,
          },
          {
            :headline => "Super headline - new",
            :description1 => "Trying to do",
            :description2 => "best description ever",
            :display_url => "bartas.cz",
            :url => "http://www.bartas.cz/",
            :status => :running,
          }
        ],
        :status => :running,
      }
      @adgroup.update(adgroup_hash)
      adgroup = SklikApi::Adgroup.get(@adgroup.args[:adgroup_id]).to_hash
      assert_equal adgroup.adtexts.size, 2
    end
  end
end