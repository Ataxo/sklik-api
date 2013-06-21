# Sklik API

Sklik advertising PPC api for creating campaigns

# Implementation

Gemfile.rb
``` ruby
gem "sklik-api", :require => "sklik-api"
```

initializers/sklik-api.rb
```ruby

# Set logger for SklikApi - default is to STDOUT
SklikApi.logger = Logger.new("log/sklik-api.log")

# when something goes wrong in creation of campaing/adgroup
# return errors and automatically rename (campaign/adgroup) with name to:
# name + FAILED CREATION + Timestamp
# and then remove it
SklikApi.use_rollback = true
#this setting can be changed on the fly!


# you can set it before every action to sklik api, if you have multiple accounts :-)
SklikApi::Access.set(
  :email => "your_email@seznam.cz",
  :password => "password",
  # :customer_id => 1112 # (optional) - this will switch you into connected account and all creation will be performed there
)
#this setting can be changed on the fly!
```

# Usage

Look at documentation on [Sklik Api](http://api.sklik.cz).

In SklikApi you have this hierarchy
* account
  * campaign
    * adgroup
      * adtext
      * keyword

# Basic usage

## Find

Find methods (on Campaign, Adgroup, Adtext, Keyword)
``` ruby
# get by campaign id
SklikApi::Campaign.get(123456)
#=> <SklikApi::Campaign:..>

# same as
SklikApi::Campaign.find(123456)
#=> <SklikApi::Campaign:..>

# with ID by hash - but it will return array!!! All finds by hash params will return array!
SklikApi::Campaign.find( campaign_id: 123456 )
#=> [<SklikApi::Campaign:..>]

# without ID and no specification - get all campaigns on logged account
SklikApi::Campaign.find()
#=> [<SklikApi::Campaign:..>,<SklikApi::Campaign:..>]

# without ID and with customer_id - get all campaigns on specified account
SklikApi::Campaign.find( customer_id: 222333 )
#=> [<SklikApi::Campaign:..>,<SklikApi::Campaign:..>]
```

You can filter response array directly in find method by status and name (if object has it)

* Find for campaigns needs to be privided with customer_id = nil || account id
* Find for adgroups needs to be privided with campaign_id
* Find for adtexts and keywords needs to be privided with adgroup_id

# Basic usage

## Save

Thera are tow ways how to save thing in Sklik Api:
* hierarchical - complete structure of for example adgroup with adtexts and keywords
* per item - one item in time creating adgroup, then keyword etc.

### Hierarchical

You will provide all data in one hash:
``` ruby
campaign_hash = {
  :name => "name of your campaign",
  :budget => 15.4, # budget is in CZK and in float
  :customer_id => 123456, #optional without specifying it will be created on logged account

  :status => :running, # [:paused, :stopped] - other options

  :excluded_search_services = [ # (optional) specify search services you don't want to use for your campaign
    2,3
  ],

  :network_setting => {
    :content => true
  }

  :ad_groups => [
    {
      :name => "my adgroup name",
      :cpc => 3.5, # cpc is in CZK and in float and is set for adgroup
      :ads => [
        {
          :headline => "Super headline",
          :description1 => "Trying to do ",
          :description2 => "best description ever",
          :display_url => "bartas.cz",
          :url => "http://www.bartas.cz",
          :status => :paused,
        }
      ],
      :keywords => [
        "\"some funny keyword\"",
        "[myphrase keyword]",
        "my broad keyword for me",
        "test of diarcritics âô"
      ]
    }
  ]
}

campaign = SklikApi::Campaign.new(campaign_hash)
unless campaign.save
  # print errors when something went wrong
  puts campaign.errors
end
```

It this way, when some error ocures in adtext creation then all errors
are posted from adtext to adgroup. and then from adgroup to campaign.

This will help you to fetch errors only on campaign (or on level where you hit save) level.

__Be aware of use_rollback setting.__
* for example adtext got error, then it will buble from adtext to campaign
  and then will rollback this campaign (if you save campaing,
  if you performed this save on adgroup level, then adgroup will be rollbacked).
  _In errors you will have answer for what went wrong._

### Per Item

You will create items by yourself:

``` ruby
campaign_hash = {
  :name => "name of your campaign",
  :budget => 15.4, # budget is in CZK and in float
  :customer_id => 123456, #optional without specifying it will be created on logged account

  :status => :running, # [:paused, :stopped] - other options

  :excluded_search_services = [ # (optional) specify search services you don't want to use for your campaign
    2,3
  ],

  :network_setting => {
    :content => true
  }
}
campaign = SklikApi::Campaign.new(campaign_hash)
#first save campaign
campaign.save

adgroup_hash = {
  #you need to set parent, where adgroup should be created (campaing_id)
  :campaign_id => campaign.args[:campaign_id],

  :name => "my adgroup name",
  :cpc => 3.5, # cpc is in CZK and in float and is set for adgroup
}

adgroup = SklikApi::Adgroup.new(adgroup_hash)
#then save adgroup
adgroup.save

adtext_hash = {
  #you need to set parent, where adtext should be created (adgroup_id)
  :adgroup_id => adgroup.args[:adgroup_id],

  :headline => "Super headline",
  :description1 => "Trying to do ",
  :description2 => "best description ever",
  :display_url => "bartas.cz",
  :url => "http://www.bartas.cz",
  :status => :paused,
}

adtext = SklikApi::Adtext.new(adtext_hash)
#then save adgroup
adtext.save

keyword_hash = {
  #you need to set parent, where adtext should be created (adgroup_id)
  :adgroup_id => adgroup.args[:adgroup_id],

  :keyword => "\"some funny keyword\""
}

keyword = SklikApi::Keyword.new(keyword_hash)
#then save adgroup
keyword.save

```
This is little bit pain in the ass, but sometimes you need full controll of the way how it is done.

## Find

Find methods (on Campaign, Adgroup, Adtext, Keyword)

``` ruby
# get by campaign id
SklikApi::Campaign.get(123456)
#=> <SklikApi::Campaign:..>

# same as
SklikApi::Campaign.find(123456)
#=> <SklikApi::Campaign:..>

# with ID by hash - but it will return array!!! All finds by hash params will return array!
SklikApi::Campaign.find( campaign_id: 123456 )
#=> [<SklikApi::Campaign:..>]

# without ID and no specification - get all campaigns on logged account
SklikApi::Campaign.find()
#=> [<SklikApi::Campaign:..>,<SklikApi::Campaign:..>]

# without ID and with customer_id - get all campaigns on specified account
SklikApi::Campaign.find( customer_id: 222333 )
#=> [<SklikApi::Campaign:..>,<SklikApi::Campaign:..>]
```

You can filter response array directly in find method by status and name (if object has it)

* Find for campaigns needs to be privided with customer_id = nil || account id
* Find for adgroups needs to be privided with campaign_id
* Find for adtexts and keywords needs to be privided with adgroup_id


## Account

mostly used for getting remaining wallet information and global statistics for whole account.

## Campaign

``` ruby
campaign_hash = {
  :name => "name of your campaign",
  :cpc => 3.5, # cpc is in CZK and in float and is set for adgroup
  :budget => 15.4, # budget is in CZK and in float
  :customer_id => 123456, #optional without specifying it will be created on logged account

  :status => :running, # [:paused, :stopped] - other options

  :excluded_search_services = [ # (optional) specify search services you don't want to use for your campaign
    2,3
  ],

  :network_setting => {
    :content => true
  }

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
        "my broad keyword for me",
        "test of diarcritics âô"
      ]
    }
  ]
}

# This model also support additional params:
# :excluded_search_services, :excluded_urls, :total_budget, :total_clicks,
#  :ad_selection, :start_date, :end_date, :premise_id
# Please look into documentation of api.sklik.cz
# http://api.sklik.cz/campaign.create.html

# this will create campaign object and do save to sklik advertising system
# if you have more than one account where to save your campaigns -> set customer_id where campaign will be created
campaign = SklikApi::Campaign.new(campaign_hash)
unless campaign.save
  # print errors when something went wrong
  puts campaign.errors
end
```

Update of Campaign

``` ruby
campaign = SklikApi::Campaign.find(:campaign_id => 12345, :customer_id => 12345).first #customer_id is optional
campaign.args[:status] = :paused
campaign.args[:name] = "Updated name of campaign"
campaign.save
#this will update status to paused and change campaign name
```
or by update method:
``` ruby
campaign = SklikApi::Campaign.find(12345)
unless campaign.update(status: :paused, name: "Updated name of campaign", budget: 20)
  # when something went wrong - check out errors!
  puts campaign.errors
end
```


# Other
Get all search services (for settings your campaigns)

``` ruby
pp SklikApi::Campaign.list_search_services
#
```

# Contributing to sklik-api

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

# Copyright

Copyright (c) 2012-2013 Ondrej Bartas. Ataxo Interactive s.r.o.


