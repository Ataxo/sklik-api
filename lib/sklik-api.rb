# -*- encoding : utf-8 -*-
require 'rubygems'
require 'rack'
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
require 'active_support/core_ext'

require 'date'
require 'logger'

ENV['RACK_ENV'] ||= "development"


#initialzie SklikApi class
class SklikApi

  def self.use_rollback= how
    @use_rollback = how
  end

  #default setting for rollback is true!
  def self.use_rollback?
    @use_rollback.nil? || @use_rollback
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.log type, message
    logger.send(type, "SklikApi: #{message}")
  rescue Exception => e
    puts "SklikApi.logger Exception: #{e.message}"
  end
end

#including sklik-api
["exceptions", "xmlrpc_setup",  "access", "connection", "sklik_object", "client", "campaign"].each do |file|
  require File.join(File.dirname(__FILE__),"/sklik-api/#{file}.rb")
end

#including config
["access"].each do |file|
  file_name = File.join(File.dirname(__FILE__),"../config/#{file}.rb")
  require file_name if File.exists?(file_name)
end


