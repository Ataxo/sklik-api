# -*- encoding : utf-8 -*-
require 'helper'
class ErrorsIntegrationTest < Test::Unit::TestCase
  context "Integration:Error - Campaign" do

    setup do
      @campaign_hash = {
        :name => "integration error - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
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
      @campaign = SklikApi::Campaign.new(@campaign_hash)
    end

    def teardown
      @campaign.remove if @campaign.args[:campaign_id] && SklikApi::Campaign.get(@campaign.args[:campaign_id]).args[:status] != :stopped
    end

    should "return errors for invalid campaign" do
      @campaign.args[:budget] = 0
      refute @campaign.valid?
      assert @campaign.errors.any?, "Campaign validation should have errors #{@campaign.errors}"

      @campaign.args[:budget] = 2
      assert @campaign.valid?, "Should be valid but got error on save"
      refute @campaign.save

      assert @campaign.errors.any?, "Campaign should have errors #{@campaign.errors}"
      assert_equal @campaign.errors, ["Campaign daybudget is too low (field = dayBudget, minimum = 1000)"]
    end

    context "-> Adgroup" do

      setup do
        #save campaign before testing!
        @campaign.save

        @adgroup_hash = {
          :name => "my adgroup name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S.%L")}",
          :cpc => 6.0,
          :campaign_id => @campaign.args[:campaign_id],
          :keywords => [],
          :ads => [],
          :status => :running,
        }
        @adgroup = SklikApi::Adgroup.new(@adgroup_hash)
      end

      should "return errors to invalid adgroup" do
        @adgroup.args[:cpc] = 0
        refute @adgroup.valid?
        assert @adgroup.errors.any?, "Adgroup validation should have errors #{@adgroup.errors}"

        @adgroup.args[:cpc] = 0.01
        assert @adgroup.valid?, "Should be valid but got error on save"
        refute @adgroup.save

        assert @adgroup.errors.any?, "Adgroup should have errors #{@adgroup.errors}"
        assert_equal @adgroup.errors, ["Group cpc is too low (field = cpc, minimum = 20)"]
      end

      should "return adgroups error into campaign errors" do
        @adgroup_hash[:cpc] = 0.01
        @campaign_hash[:ad_groups] = [@adgroup_hash]
        @campaign_hash.delete(:campaign_id)
        @campaign_hash[:name] += " Second level"
        @campaign = SklikApi::Campaign.new(@campaign_hash)
        refute @campaign.save, "Shouldn't be saved"
        assert @campaign.errors.any?, "Campaign should have errors #{@campaign.errors}"
        assert @campaign.errors.first =~ /Group cpc is too low/, "#{@campaign.errors} should have error from adgroup /Group cpc si too low/"
      end

      should "return adgroups error into campaign errors && rollback!" do

        SklikApi.use_rollback = true

        @adgroup_hash[:cpc] = 0.01
        @campaign_hash[:ad_groups] = [@adgroup_hash]
        @campaign_hash.delete(:campaign_id)
        @campaign_hash[:name] += " Second level"
        old_name = "#{@campaign_hash[:name]}"
        @campaign = SklikApi::Campaign.new(@campaign_hash)
        refute @campaign.save, "Shouldn't be saved"
        assert @campaign.errors.any?, "Campaign should have errors #{@campaign.errors}"
        assert @campaign.errors.first =~ /Group cpc is too low/, "#{@campaign.errors} should have error from adgroup /Group cpc si too low/"

        campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
        assert_not_equal old_name, campaign.args[:name], "Names should be diferent: #{@campaign_hash[:name]} != #{campaign.args[:name]}"
        assert_equal campaign.args[:status], :stopped, "Campaign should be stopped after rollback"
      end

      should "return adgroups error into campaign errors && dont rollback!" do

        SklikApi.use_rollback = false

        @adgroup_hash[:cpc] = 0.01
        @campaign_hash[:ad_groups] = [@adgroup_hash]
        @campaign_hash.delete(:campaign_id)
        @campaign_hash[:name] += " Second level"
        @campaign = SklikApi::Campaign.new(@campaign_hash)
        refute @campaign.save, "Shouldn't be saved"
        assert @campaign.errors.any?, "Campaign should have errors #{@campaign.errors}"
        assert @campaign.errors.first =~ /Group cpc is too low/, "#{@campaign.errors} should have error from adgroup /Group cpc si too low/"

        campaign = SklikApi::Campaign.get(@campaign.args[:campaign_id])
        assert_equal @campaign_hash[:name], campaign.args[:name], "Names should be same: #{@campaign_hash[:name]} == #{campaign.args[:name]}"
        assert_equal campaign.args[:status], :running, "Campaign should be running and without rollback"
      end

      context "-> Adtext" do

        setup do
          @adgroup.save
          @adtext_hash = {
            :adgroup_id => @adgroup.args[:adgroup_id],
            :headline => "Super headline",
            :description1 => "Trying to do ",
            :description2 => "best description ever",
            :display_url => "bartas.cz",
            :url => "http://www.bartas.cz/",
            :status => :running,
          }
          @adtext = SklikApi::Adtext.new(@adtext_hash)
        end

        should "return errors to invalid adtext" do
          @adtext.args[:headline] = ""
          refute @adtext.valid?
          assert @adtext.errors.any?, "Adtext validation should have errors #{@adtext.errors}"

          @adtext.args[:headline] = "Long head valid not by sklik"
          assert @adtext.valid?, "Should be valid - got: #{@adtext.errors}"
          refute @adtext.save

          assert @adtext.errors.any?, "Adtext should have errors #{@adtext.errors}"
          assert_equal @adtext.errors, ["Creative1 is too long (field = creative1)"]
        end

        should "return adgroups error into campaign errors" do
          @adgroup_hash.delete(:adgroup_id)
          @campaign_hash.delete(:campaign_id)

          @adtext_hash[:headline] = "Long head valid not by sklik"
          @adgroup_hash[:ads] = [@adtext_hash]
          @adgroup_hash[:name] += " Third level"
          @campaign_hash[:ad_groups] = [@adgroup_hash]
          @campaign_hash[:name] += " Third level"
          @campaign = SklikApi::Campaign.new(@campaign_hash)
          refute @campaign.save, "Shouldn't be saved"
          assert @campaign.errors.any?, "Campaign should have errors #{@campaign.errors}"
          assert @campaign.errors.first =~ /Creative1 is too long/, "#{@campaign.errors} should have error from adgroup /Creative1 is too long/"
        end

      end
    end
  end
end