# -*- encoding : utf-8 -*-
class SklikApi
  class Adtext

    NAME = "ad"

    ADDITIONAL_FIELDS = [
      :premiseMode, :premiseID
    ]

    include SklikObject
=begin
Example of input hash
{
  :headline => "Super headline",
  :description1 => "Trying to do ",
  :description2 => "best description ever",
  :display_url => "my_test_url.cz",
  :url => "http://my_test_url.cz"
}


=end

    def initialize adgroup, args
      @adtext_data = nil
      #set adtext owner adgroup
      @adgroup = adgroup

      super args
    end

    def uniq_identifier
      "#{@args[:headline]}#{@args[:description1]}#{@args[:description2]}#{@args[:display_url]}#{@args[:url]}"
    end

    def create_args
      raise ArgumentError, "Adtexts need's to know adgroup_id" unless @adgroup.args[:adgroup_id]
      out = []
      #add campaign id to know where to create adgroup
      out << @adgroup.args[:adgroup_id]

      #add adtext struct
      args = {}
      args[:creative1] = @args[:headline]
      args[:creative2] = @args[:description1]
      args[:creative3] = @args[:description2]
      args[:clickthruText] = @args[:display_url]
      args[:clickthruUrl] = @args[:url]

      ADDITIONAL_FIELDS.each do |add_info|
        field_name = add_info.to_s.underscore.to_sym
        args[add_info] = @args[field_name] if @args[field_name]
      end

      out << args

      #return output
      out
    end

    def self.find adgroup, args = {}
       out = []
       super(NAME, adgroup.args[:adgroup_id]).each do |adtext|
         if args[:adtext_id].nil? || (args[:adtext_id] && args[:adtext_id].to_i == adtext[:id].to_i)
           out << SklikApi::Adtext.new(
             adgroup,
             :adtext_id => adtext[:id],
             :headline => adtext[:creative1],
             :description1 => adtext[:creative2],
             :description2 => adtext[:creative3],
             :display_url =>adtext[:clickthruText],
             :url => adtext[:clickthruUrl],
             :name => adtext[:name],
             :status => fix_status(adtext)
           )
         end
       end
       out
     end

     def self.fix_status adtext
       if adtext[:removed] == true
         return :stopped
       elsif adtext[:status] == "active"
         return :running
       elsif adtext[:status] == "suspend"
         return :paused
       else
         return :unknown
       end
     end

    def to_hash
      if @adtext_data
        @adtext_data
      else
        @adtext_data = @args
      end
    end

    def save
      if @args[:adtext_id]  #do update

      else                    #do save
        #create adtext
        create
      end
    end
  end
end

