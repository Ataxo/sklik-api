# -*- encoding : utf-8 -*-
require 'rubygems'
require 'rack'
require 'pp'
require 'json'
require 'unicode'
require 'uri'

#for sklik miner
require 'net/http'
require 'net/https'
require "xmlrpc/client"

require 'active_support'
require 'active_support/inflector'
require 'active_support/inflector/inflections'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext'

require 'date'
require 'logger'

ENV['RACK_ENV'] ||= "development"


#initialzie SklikApi class
class SklikApi
  
end

#including sklik-api
["xmlrpc_setup",  "access", "connection", "sklik_object", "campaign"].each do |file|
  require File.join(File.dirname(__FILE__),"/sklik-api/#{file}.rb")
end

#including config
["access"].each do |file|
  require File.join(File.dirname(__FILE__),"../config/#{file}.rb")
end


