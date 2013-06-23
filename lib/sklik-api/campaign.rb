# -*- encoding : utf-8 -*-
class SklikApi
  class Campaign

    NAME = "campaign"

    ADDITIONAL_FIELDS = [
      :excludedSearchServices, :excludedUrls, :totalBudget, :totalClicks,
      :adSelection, :startDate, :endDate, :premiseId
    ]

    include SklikObject
=begin
Example of input hash
{
  :campaign_id => 12345, #(OPTIONAL) -> when setted it will on save do update of existing campaign
  :name => "my campaign name - #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}",
  :status => :running,
  :budget => 50, #in CZK

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
          :display_url => "my_test_url.cz",
          :url => "http://my_test_url.cz"
        }
      ],
      :keywords => [
        "\"some funny keyword\"",
        "[phrase keyword]",
        "broad keyword for me",
        "test of diarcritics âô"
      ]
    }
  ]
}

# This model also support additional params:
# :excluded_search_services, :excluded_urls, :total_budget, :total_clicks,
#  :ad_selection, :start_date, :end_date, :status, :premise_id
# Please look into documentation of api.sklik.cz
# http://api.sklik.cz/campaign.create.html
=end

    def initialize args
      #variable where are saved current data from system
      @campaign_data = nil

      @args = args

      #initialize adgroups
      @adgroups = []
      if args[:ad_groups] && args[:ad_groups].size > 0
        args[:ad_groups].each do |adgroup|
          @adgroups << SklikApi::Adgroup.new(adgroup.merge(:campaign => self))
        end
      end

      @customer_id = args[:customer_id]
      super args
    end

    def self.get id
      return ArgumentError, "Please provide param (campaign id)" unless id
      if campaign = super(NAME, id)
        SklikApi::Campaign.new(process_sklik_data campaign)
      else
        nil
      end
    end

    def self.find args = {}
      out = []

      #asking fo campaign by ID
      if args.is_a?(Integer)
        return get args

      #asking for campaign by hash with adgroup_id
      elsif args.is_a?(Hash) && args[:campaign_id]
        if campaign = get(args[:campaign_id])
          return [campaign]
        else
          return []
        end
      end

      super(NAME, args[:customer_id]).each do |campaign|
        if (args[:status].nil? || (args[:status] && args[:status] == fix_status(campaign))) && # find by status
          (args[:name].nil? || (args[:name] == campaign[:name]))
          out << SklikApi::Campaign.new(process_sklik_data campaign)
        end
      end
      out
    end

    def self.process_sklik_data campaign = {}
      {
        :campaign_id => campaign[:id],
        :customer_id => campaign[:userId],
        :budget => campaign[:dayBudget].to_f/100.0,
        :name => campaign[:name],
        :status => fix_status(campaign),
        :excluded_search_services => campaign[:excludedSearchServices],
        :network_setting=> {:content=>campaign[:context], :search=>true}
      }
    end

    def self.list_search_services
      connection.call("listSearchServices") do |param|
        return param[:searchServices].collect{|c| c.symbolize_keys}
      end
    end

    def self.fix_status campaign
      if campaign[:removed] == true
        return :stopped
      elsif campaign[:status] == "active"
        return :running
      elsif campaign[:status] == "suspend"
        return :paused
      else
        return :unknown
      end
    end

    def adgroups
      if @args[:campaign_id] && get_current_status == :stopped
        SklikApi.log :error, "Campaign: #{@args[:campaign_id]} - Can't get adgroups for stopped Campaign!"
        []
      else
        Adgroup.find(campaign_id: self.args[:campaign_id])
      end
    end

    def to_hash
      if @campaign_data
        @campaign_data
      else
        @campaign_data = @args
        if @args[:status] != :stopped
          @campaign_data[:ad_groups] = Adgroup.find(campaign_id: self.args[:campaign_id]).collect{|a| a.to_hash}
        else
          @campaign_data[:ad_groups] = []
        end
        @campaign_data
      end
    end

    def update_args
      out = []

      #add campaign id on which will be performed update
      out << @args[:campaign_id]

      #prepare campaign struct
      u_args = {}
      u_args[:name] = @args[:name] if @args[:name]
      u_args[:status] = status_for_update if status_for_update
      u_args[:dayBudget] = (@args[:budget] * 100).to_i if @args[:budget]
      u_args[:context] = @args[:network_setting][:content].nil? || @args[:network_setting][:content]  if @args[:network_setting]
      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        u_args[add_info] = @args[field_name] if @args[field_name]
      end

      out << u_args

      out
    end

    def create_args
      out = []

      #prepare campaign struct
      c_args = {}
      c_args[:name] = @args[:name]
      c_args[:status] = status_for_update if status_for_update
      c_args[:dayBudget] = (@args[:budget] * 100).to_i if @args[:budget]
      c_args[:context] = @args[:network_setting][:content].nil? || @args[:network_setting][:content] if @args[:network_setting]
      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        c_args[add_info] = @args[field_name] if @args[field_name]
      end
      out << c_args

      #add customer id on which account campaign should be created
      out << @customer_id if @customer_id
      out
    end

    def self.get_current_status args = {}
      raise ArgumentError, "Campaign_id is required" unless args[:campaign_id]
      if campaign = self.get(args[:campaign_id])
        campaign.args[:status]
      else
        raise ArgumentError, "Campaign by #{args.inspect} couldn't be found!"
      end
    end

    def get_current_status
      self.class.get_current_status :campaign_id => @args[:campaign_id], :customer_id => @customer_id
    end

    def update args = {}
      @args.merge!(args)

      #initialize update of adgroups adgroups
      @adgroups = []
      if args[:ad_groups] && args[:ad_groups].size > 0
        @adgroups_update = true
        args[:ad_groups].each do |adgroup|
          @adgroups << SklikApi::Adgroup.new(adgroup.merge(campaign: self))
        end
      end

      save
    end

    def valid?
      clear_errors
      log_error "name is required" unless args[:name] && args[:name].size > 0
      log_error "budget must be more than 1 CZK" unless args[:budget] && args[:budget] > 1.0
      !errors.any?
    end

    def save
      clear_errors
      if @args[:campaign_id]  #do update
        #get current status of campaign
        before_status = get_current_status

        #restore campaign before update
        restore if before_status == :stopped

        #rescue from any error to ensure remove will be done when something went wrong
        error = nil
        begin
          #update campaign
          update_object

          #update adgroups!
          if @adgroups_update
            @saved_adgroups = adgroups.inject({}){|o,a| o[a.args[:name]] = a; o}
            @new_adgroups = @adgroups.inject({}){|o,a| o[a.args[:name]] = a; o}
            #adgroups to be deleted
            (@saved_adgroups.keys - @new_adgroups.keys).each do |k|
              #don't try to remove already removed adgroup
              unless @saved_adgroups[k].args[:status] == :stopped
                puts "removing old adgroup: #{@saved_adgroups[k].args[:name]}"
                @saved_adgroups[k].remove
              end
            end

            #adgroups to be created
            (@new_adgroups.keys - @saved_adgroups.keys).each do |k|
              puts "creating new adgroup: #{@new_adgroups[k].args[:name]}"
              unless @new_adgroups[k].save
                log_error({"Creation of: #{@new_adgroups[k].args[:name]}"=> @new_adgroups[k].errors})
              end
            end

            #check status to be running
            (@new_adgroups.keys & @saved_adgroups.keys).each do |k|
              puts "checking status of adgroup: #{@saved_adgroups[k].args[:name]}"
              if @saved_adgroups[k].args[:status] == :stopped
                @saved_adgroups[k].restore
              end
              puts "updating adgroup: #{@saved_adgroups[k].args[:name]}"
              unless @saved_adgroups[k].update @new_adgroups[k]
                log_error({"Creation of: #{@saved_adgroups[k].args[:name]}"=> @saved_adgroups[k].errors})
              end
            end

          end

        rescue Exception => e
          log_error e.message
        end

        #remove it if new status is stopped or status doesn't changed and before it was stopped
        remove if (@args[:status] == :stopped) || (@args[:status].nil? && before_status == :stopped)

      else                    #do save
        #create campaign
        begin
          create
        rescue Exception => e
          log_error e.message
          #don't continue with creating campaign!
          return false
        end

        #create adgroups
        unless @adgroups.all?{ |adgroup| adgroup.save }
          return rollback!
        end

        @campaign_data = @args

        #remove campaign when it was started with stopped status!
        remove if @args[:status] && @args[:status].to_s.to_sym == :stopped

      end

      !errors.any?
    end

    def log_error message
      errors << message
    end

    def rollback! suffix = "FAILED ON CREATION"
      #don't rollback if it is disabled!
      return false unless SklikApi.use_rollback?

      #remember errors!
      old_errors = errors

      SklikApi.log :info, "Campaign: #{@args[:campaign_id]} - ROLLBACK!"
      update :name => "#{@args[:name]} #{suffix} - #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}"
      #remove adgroup
      remove

      #return remembered errors!
      @errors = old_errors
      #don't continue with creating adgroup!
      return false
    end
  end
end

#include campaign parts
["keyword", "adtext", "adgroup"].each { |file| require File.join(File.dirname(__FILE__), "campaign_parts/#{file}.rb") }
