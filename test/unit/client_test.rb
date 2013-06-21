# -*- encoding : utf-8 -*-
require 'helper'
class ClientTest < Test::Unit::TestCase
  context "Client" do
    
    should "be initialized" do
      assert_nothing_raised do
        SklikApi::Client.new()
      end  
    end

    should "found all Clients" do
      assert_equal SklikApi::Client.find().size, 2
    end
      
    should "be found by id" do 
      assert_equal SklikApi::Client.find(:customer_id => 192107).first.args[:email], "test-ataxo@seznam.cz"
      assert_equal SklikApi::Client.find(:customer_id => 192495).first.args[:email], "test3-ataxo@seznam.cz"
    end    
    
    should "be found by email" do 
      assert_equal SklikApi::Client.find(:email => "test-ataxo@seznam.cz").first.args[:customer_id], 192107
      assert_equal SklikApi::Client.find(:email => "test3-ataxo@seznam.cz").first.args[:customer_id], 192495
    end    
    
  end
end