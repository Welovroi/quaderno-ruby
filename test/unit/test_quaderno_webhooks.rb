require 'helper'

class TestQuadernoWebhook < Test::Unit::TestCase
  context "A user with an authenticate token with webhooks" do

    setup do
      Quaderno::Base.configure do |config|
      	config.auth_token = 'n8sDLUZ5z1d6dYXKixnx'
      	config.subdomain = 'recrea'
      end    
    end

    should "get exception if pass wrong arguments" do
      assert_raise ArgumentError do 
        VCR.use_cassette('all webhooks') do
          Quaderno::Webhook.all 1, 2, 3
        end
      end
      assert_raise ArgumentError do 
        VCR.use_cassette('found webhook') do
          Quaderno::Webhook.find
        end
      end
    end

    should "get all webhooks (populated db)" do
      VCR.use_cassette('all webhooks') do
      	webhook_1 = Quaderno::Webhook.create(url: 'http://google.com', events: ['created', 'updated'])
        webhook_2 = Quaderno::Webhook.create(url: 'http://quadernoapp.com', events: ['created', 'updated', 'deleted'])
        webhooks = Quaderno::Webhook.all
        assert_not_nil webhooks
        assert_kind_of Array, webhooks
        webhooks.each do |webhook|
          assert_kind_of Quaderno::Webhook, webhook
        end
        Quaderno::Webhook.delete webhook_1.id
        Quaderno::Webhook.delete webhook_2.id
      end
    end

    should "find a webhook" do
      VCR.use_cassette('found webhook') do
        webhook = Quaderno::Webhook.create(url: 'http://quadernoapp.com', events: ['created', 'updated'])
        webhooks = Quaderno::Webhook.all
        assert_kind_of Quaderno::Webhook, webhook
        assert_equal webhooks.last.id, webhook.id
        Quaderno::Webhook.delete webhook.id
      end
    end
    
    should "create a webhook" do
      VCR.use_cassette('new webhook') do
        webhook = Quaderno::Webhook.create(url: 'http://quadernoapp.com', events: ['created', 'updated'])
        assert_kind_of Quaderno::Webhook, webhook
        assert_equal 'https://quadernoapp.com', webhook.url
        assert_equal ['created', 'updated'], webhook.events
        Quaderno::Webhook.delete webhook.id
      end
    end
    
    should "update a webhook" do
      VCR.use_cassette('updated webhook') do
      	Quaderno::Webhook.create(url: 'http://quadernoapp.com', events: ['created', 'updated'])
        webhooks = Quaderno::Webhook.all
        webhook = Quaderno::Webhook.update(webhooks.last.id, events: ['created', 'updated', 'deleted'])
        assert_kind_of Quaderno::Webhook, webhook
        assert_equal ['created', 'updated', 'deleted'], webhook.events
        Quaderno::Webhook.delete webhook.id
      end
    end
    
    should "delete a webhook" do
        VCR.use_cassette('deleted webhook') do
          webhook_1 = Quaderno::Webhook.create(url: 'http://google.com', events: ['created', 'updated'])
          webhook_2 = Quaderno::Webhook.create(url: 'http://quadernoapp.com', events: ['created', 'updated'])
          webhooks_before = Quaderno::Webhook.all
          webhook_id = webhooks_before.last.id
          Quaderno::Webhook.delete webhook_id
          webhooks_after = Quaderno::Webhook.all
          assert_not_equal webhooks_after.last.id, webhook_id
          Quaderno::Webhook.delete webhooks_after.last.id
        end
    end
    
    should "know the rate limit" do
      VCR.use_cassette('rate limit') do
        rate_limit_info = Quaderno::Base.rate_limit_info
        assert_equal 1000, rate_limit_info[:limit]
        assert_operator rate_limit_info[:remaining], :< ,1000     
      end
    end
  end
end