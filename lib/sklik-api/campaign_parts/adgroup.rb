# -*- encoding : utf-8 -*-
class SklikApi
  class Adgroup

    NAME = "group"

    include SklikObject
=begin
Example of input hash
{
  :adgroup_id => 1234, #(OPTIONAL) -> when setted it will on save do update of existing adgroup
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


=end

    def initialize args, deprecated_args = {}

      #deprecated way to set up new adgroup!
      if args.is_a?(SklikApi::Campaign)
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Adgroup.new(campaign, args) to SklikApi::Adgroup.new(args = {}) possible to add parent camapign by adding :campaign => your campaign"
        #set adgroup owner campaign
        @campaign = args
        args = deprecated_args

      #new way to set adgroups!
      else
        #set adgroup owner campaign
        #if in input args there is pointer to parent campaign!
        if @campaign = args.delete(:campaign)
          # if no cpc was given - try to use campaign cpc
          if !args[:cpc] && @campaign.args[:cpc]
            args[:cpc] = @campaign.args[:cpc]
          end
        end
      end
      @args = args

      @adgroup_data = nil

      #initialize adgroups
      @adtexts = []
      if args[:ads] && args[:ads].size > 0
        args[:ads].each do |adtext|
          @adtexts << SklikApi::Adtext.new(adtext.merge(:adgroup => self))
        end
      end

      #initialize adgroups
      @keywords = []
      if args[:keywords] && args[:keywords].size > 0
        args[:keywords].each do |keyword|
          if keyword.is_a?(Hash)
            @keywords << SklikApi::Keyword.new(keyword.merge(:adgroup => self))
          else
            @keywords << SklikApi::Keyword.new(:keyword => keyword, :adgroup => self)
          end
        end
      end

      super args
    end

    def self.get id
      if adgroup = super(NAME, id)
        SklikApi::Adgroup.new(
          process_sklik_data adgroup
        )
      else
        nil
      end
    end
    #
    # Find adgroups in campaign!
    # !Deprecated! by campaign and args
    #
    def self.find args, deprecated_args = {}
      out = []
      #asking fo adgroup by ID
      if args.is_a?(Integer)
        return get args

      #asking for adgroup deprecated way!
      elsif args.is_a?(SklikApi::Campaign)
        puts "DEPRECATION WARNING: Please update your code for SklikApi::Adgroup.find(campaign, args) to SklikApi::Adgroup.find(campaign_id: 1234) possible to add parent camapign by adding :campaign => your campaign"
        campaign_id = args.args[:campaign_id]
        args = deprecated_args

      #asking for adgroup by hash with adgroup_id
      elsif args.is_a?(Hash) && args[:adgroup_id]
        if adgroup = get(args[:adgroup_id])
          return [adgroup]
        else
          return []
        end

      #asking for adgroup by hash
      else
        campaign_id = args[:campaign_id]
      end

      raise ArgumentError, "Please provide campaign_id in params" unless campaign_id

      super(NAME, campaign_id).each do |adgroup|

        if (args[:status].nil? || (args[:status] == fix_status(adgroup)))  && # find by status
          (args[:name].nil? || (args[:name] == adgroup[:name]))

          out << SklikApi::Adgroup.new(
            process_sklik_data adgroup
          )
        end
      end
      out
    end

    def self.process_sklik_data adgroup = {}
      {
        :adgroup_id => adgroup[:id],
        :cpc => adgroup[:cpc].to_f/100.0,
        :name => adgroup[:name],
        :status => fix_status(adgroup),
        :campaign_id => adgroup[:campaignId],
      }
    end

    def self.fix_status adgroup
      if adgroup[:removed] == true
        return :stopped
      elsif adgroup[:status] == "suspend"
        return :paused
      else
        return :running
      end
    end

    def keywords_stats from, to
      output = []
      keywords = Keyword.find(adgroup_id: self.args[:adgroup_id])
      keywords.in_groups_of(100, false).each do |keywords_group|
        out = connection.call("keywords.stats", keywords_group.collect{|k| k.args[:keyword_id]}, from, to ) { |param|
          param[:keywordStats]
        }
        out.each do |kw_stats|
          kws = keywords_group.select{|k| k.args[:keyword_id] == kw_stats["keywordId"]}
          if kws.size == 1
            kw = keywords_group.delete(kws.first)
            kw.stats = {:fulltext => underscore_hash_keys(kw_stats["stats"]) }
            output << kw
          end
        end
      end
      output
    end

    def to_hash
      if @adgroup_data
        @adgroup_data
      else
        @adgroup_data = @args
        @adgroup_data[:ads] = self.adtexts.collect{|a| a.to_hash}
        @adgroup_data[:keywords] = self.keywords.collect{|k| k.to_hash}
        @adgroup_data
      end
    end


    def create_args
      raise ArgumentError, "Adgroup need's to know campaign_id" unless args[:campaign_id]
      raise ArgumentError, "Adgroup need's to know campaigns CPC" unless args[:cpc]

      out = []
      #add campaign id to know where to create adgroup
      out << @args[:campaign_id] || @campaign.args[:campaign_id]

      #add adgroup struct
      c_args = {}
      c_args[:name] = @args[:name]
      if @args[:cpc]
        c_args[:cpc] = (@args[:cpc] * 100).to_i
      elsif @campaign && @campaign.args[:cpc]
        c_args[:cpc] = (@campaign.args[:cpc] * 100).to_i
      else
        raise ArgumentError, "Please provide adgroup or parent campaign with :cpc parameter in CZK"
      end
      c_args[:status] = status_for_update if status_for_update
      out << c_args

      #return output
      out
    end

    def update_args
      out = []

      #add campaign id on which will be performed update
      out << @args[:adgroup_id]

      #prepare campaign struct
      u_args = {}
      u_args[:name] = @args[:name] if @args[:name]
      u_args[:status] = status_for_update if status_for_update
      if @args[:cpc]
        u_args[:cpc] = (@args[:cpc] * 100).to_i
      elsif @campaign && @campaign.args[:cpc]
        u_args[:cpc] = (@campaign.args[:cpc] * 100).to_i
      end
      out << u_args

      out
    end

    def adtexts
      if @args[:adgroup_id] && get_current_status == :stopped
        SklikApi.log :error, "Adgroup: #{@args[:adgroup_id]} - Can't get adtexts for stopped Adgroup!"
        []
      else
        Adtext.find(adgroup_id: self.args[:adgroup_id])
      end
    end

    def keywords
      if @args[:adgroup_id] && get_current_status == :stopped
        SklikApi.log :error, "Adgroup: #{@args[:adgroup_id]} - Can't get keywords for stopped Adgroup!"
        []
      else
        Keyword.find(adgroup_id: self.args[:adgroup_id])
      end
    end

    def update args = {}

      @args.merge!(args)

      if args.is_a?(SklikApi::Adgroup)
        #get data from another adgroup
        @adtexts = args.instance_variable_get("@adtexts")
        @keywords = args.instance_variable_get("@keywords")

        #set parent to this adgroup
        @adtexts.each{|a| a.instance_variable_set("@adgroup", self)}
        @keywords.each{|a| a.instance_variable_set("@adgroup", self)}
      else
        #initialize new adtexts
        @adtexts = []
        if args[:ads] && args[:ads].size > 0
          args[:ads].each do |adtext|
            @adtexts << SklikApi::Adtext.new(adtext.merge(:adgroup => self))
          end
        end

        #initialize new keywords
        @keywords = []
        if args[:keywords] && args[:keywords].size > 0
          args[:keywords].each do |keyword|
            @keywords << SklikApi::Keyword.new(:keyword => keyword, :adgroup => self)
          end
        end
      end

      save
    end

    def valid?
      clear_errors
      log_error "name is required" unless args[:name] && args[:name].size > 0
      log_error "cpc is required and must be higher than 0 CZK" unless !@args[:adgroup_id] && args[:cpc] && args[:cpc] > 0
      log_error "campaign_id is required" unless args[:campaign_id] || (@campaign && @campaign.args[:campaign_id])
      !errors.any?
    end


    def self.get_current_status args = {}
      raise ArgumentError, "Adgroup_id is required" unless args[:adgroup_id]
      if adgroup = self.get(args[:adgroup_id])
        adgroup.args[:status]
      else
        raise ArgumentError, "Adgroup by #{args.inspect} couldn't be found!"
      end
    end

    def get_current_status
      self.class.get_current_status :adgroup_id => @args[:adgroup_id], :customer_id => @customer_id
    end

    def save
      clear_errors
      @args[:campaign_id] = @campaign.args[:campaign_id] if !@args[:campaign_id] && @campaign.args[:campaign_id]

      if @args[:adgroup_id]  #do update

        #get current status of campaign
        before_status = get_current_status

        #restore campaign before update
        restore if before_status == :stopped

        #rescue from any error to ensure remove will be done when something went wrong
        error = nil

        begin
          #update adgroup
          update_object

          ############
          ## KEYWORDS
          ############

          #update keywords
          keywords_error = []
          @new_keywords = @keywords.clone
          delete_first = true
          while @new_keywords && @new_keywords.size > 0 do
            begin
              connection.call('keywords.set', @args[:adgroup_id], @new_keywords[0..199].collect{|k| k.create_args.last }, delete_first) do |params|
                log_error params[:statusMessage] if params[:statusMessage] != "OK"
              end
            rescue Exception => e
              log_error e.message
            end
            @new_keywords = @new_keywords[200..-1]
            delete_first = false
          end

          ############
          ## ADTEXTS
          ############

          #create new adtexts and delete old
          @saved_adtexts = adtexts.inject({}){|o,a| o[a.uniq_identifier] = a ; o}
          @new_adtexts = @adtexts.inject({}){|o,a| o[a.uniq_identifier] = a ; o}

          #adtexts to be deleted
          (@saved_adtexts.keys - @new_adtexts.keys).each do |k|
            puts "deleting adtext #{@saved_adtexts[k]} in #{@args[:name]}"
            #don't try to remove already removed adtext
            @saved_adtexts[k].remove  unless @saved_adtexts[k].args[:status] == :stopped
          end

          #adtexts to be created
          (@new_adtexts.keys - @saved_adtexts.keys).each do |k|
            puts "creating new adtext #{k} in #{@args[:name]}"
            begin
              @new_adtexts[k].save
            rescue Exception => e
              #take care about error message -> do it nicer
              if /There is error from sklik ad.create: Invalid parameters/ =~ e.message
                log_error "Problem with creating #{@new_adtexts[k].args} in adgroup #{@args[:name]}"
              else
                log_error e.message
              end
            end
          end

          #check status to be running
          (@new_adtexts.keys & @saved_adtexts.keys).each do |k|
            @saved_adtexts[k].restore if @saved_adtexts[k].args[:status] == :stopped
          end

        rescue Exception => e
          log_error e.message
        end

        #remove it if new status is stopped or status doesn't changed and before it was stopped
        remove if (@args[:status] == :stopped) || (@args[:status].nil? && before_status == :stopped)

      else #do create

        begin
          #create adgroup
          create
        rescue Exception => e
          log_error e.message
          #don't continue with creating campaign!
          return false
        end

        #create adtexts
        unless @adtexts.all?{|adtext| adtext.save }
          return rollback!
        end

        #create keywords
        keywords_error = []
        @new_keywords = @keywords.clone
        delete_first = true
        while @new_keywords && @new_keywords.size > 0 do
          begin
            connection.call('keywords.set', @args[:adgroup_id], @new_keywords[0..199].collect{|k| k.create_args.last }, delete_first) do |params|
              keywords_error << params[:statusMessage] if params[:statusMessage] != "OK"
            end
          rescue Exception => e
            keywords_error << e.message
          end
          @new_keywords = @new_keywords[200..-1]
          delete_first = false
        end

        if keywords_error.size > 0
          log_error  "Problem with creating keywords: #{keywords_error.join(", ")}"
          return rollback!
        end

        #remove campaign when it was started with stopped status!
        remove if @args[:status] && @args[:status].to_s.to_sym == :stopped

      end
      !errors.any?
    end

    def log_error message
      @campaign.log_error "Adgroup: #{@args[:name]} -> #{message}" if @campaign
      errors << message
    end

    def rollback!
      #don't rollback if it is disabled!
      return false unless SklikApi.use_rollback?

      #remember errors!
      old_errors = errors

      SklikApi.log :info, "Adgroup: #{@args[:adgroup_id]} - ROLLBACK!"
      update :name => "#{@args[:name]} FAILED ON CREATION - #{Time.now.strftime("%Y.%m.%d %H:%M:%S")}"
      #remove adgroup
      remove

      #return remembered errors!
      @errors = old_errors
      #don't continue with creating adgroup!
      return false
    end
  end
end

