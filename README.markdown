# Sklik API

Sklik advertising PPC api for creating campaigns

# Implementation

Gemfile.rb
``` ruby
gem "sklik-api", :require => "sklik-api"
```



# Usage 

Campaign creation

``` ruby
campaign_hash = {
  :name => "name of your campaign",
  :cpc => 3.5, # cpc is in CZK and in float and is set for adgroup
  :budget => 15.4, # budget is in CZK and in float 
  :customer_id => 123456, #optional without specifying it will be created on logged account
  
  :excluded_search_services = [ # (optional) specify search services you don't want to use for your campaign
    2,3
  ],
  
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
        "my broad keyword for me",
        "test of diarcritics âô"
      ]
    }
  ]
}

#you can set it before every action to sklik api, if you have multiple accounts :-)
SklikApi::Access.set(
  :email => "your_email@seznam.cz",
  :password => "password"
)

# this will create campaign object and do save to sklik advertising system
# if you have more than one account where to save your campaigns -> set customer_id where campaign will be created
SklikApi::Campaign.new(campaign_hash).save
```

Update of Campaign

``` ruby
campaign = SklikApi::Campaign.find(:campaign_id => 12345, :customer_id => 12345).first #customer_id is optional
campaign.args[:status] = :paused
campaign.args[:name] = "Updated name of campaign"
campaign.save
#this will update status to paused and change campaign name
```

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

Copyright (c) 2012 Ondrej Bartas. See LICENSE.txt for
further details.

