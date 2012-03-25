# -*- encoding : utf-8 -*-

def register_uri(name, uri_full)
  uri = URI.parse(uri_full)
  unless File.exists?("./test/fixtures/uri_#{name}.fake")
    pp "downloading new fixture from #{uri_full}"
    system "curl -s -i -G -d \"#{uri.query}\" #{uri.host}:#{uri.port}#{uri.path} > ./test/fixtures/uri_#{name}.fake" 
  end
  FakeWeb.register_uri(:get, "#{uri_full}", :response => "./test/fixtures/uri_#{name}.fake")
  #p "added #{@count_uries} url to fake web"
end

def register_uri_post(name, uri_full)
  uri = URI.parse(uri_full)
  if File.exists?("./test/fixtures_post_body/#{name}.txt")
    unless File.exists?("./test/fixtures/#{name}.fake")
      pp "downloading new fixture from POST #{uri_full}"
      system "curl -s -d \"@test/fixtures_post_body/post_body_#{name}.txt\" #{uri.host}:#{uri.port}#{uri.path} > ./test/fixtures/uri_#{name}.fake" 
    end
    body = ""
    File.open("./test/fixtures/uri_#{name}.fake", "r:UTF-8") do |fo|
      while( line = fo.gets) do
        body += line
      end
    end
    FakeWeb.register_uri(:post, "#{uri_full}", :body => body)
  else
    puts "YOU NEED TO CREATE FILE: test/fixtures_post_body/post_body_#{name}.txt which will contain POST body"
  end
  #p "added #{@count_uries} url to fake web"
end


#reports
#register_uri("foreman_report", "http://127.0.0.1:8877/report/foreman_report/adwords/ataxo/6170748009/1072676132/ALL_TIME")

#register_uri_post("refinery_relations_ataxo", "http://refinery.stage.internal.ataxo.com/relations/ataxo")

FakeWeb.allow_net_connect = true
p "FakeWeb registered and set to allow net connection: #{FakeWeb.allow_net_connect?}"