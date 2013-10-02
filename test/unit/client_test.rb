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
      assert_equal SklikApi::Client.find().size, 1
    end

    should "be found by id" do
      assert_equal SklikApi::Client.find(:customer_id => 250497).first.args[:email], "test-travis@seznam.cz"
    end

    should "be found by email" do
      assert_equal SklikApi::Client.find(:email => "test-travis@seznam.cz").first.args[:customer_id], 250497
    end

  end
end