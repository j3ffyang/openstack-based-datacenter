require "rubygems"
require 'net/http'
require 'uri'
require 'ping'

Given(/^IMM IP list file "(.*?)"$/) do |file|
  @imm_ips = []  
  File.open(file, "r").each_line do |line|
    @imm_ips.push line.split(" ")
  end
end

Then(/^I access to all IMM addr$/) do
  
  @imm_ips.each do |ip, user, password|
    uri = URI.parse("http://#{ip}")
    puts "login #{uri} with #{user}:#{password}"
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.post("/", "USERNAME=#{user},PASSWORD=#{password}")
    expect(response.code).to eq "200"
  end
end

Then(/^I access to all Management addr "(.*?)"$/) do |file|

  ips = []
  File.open(file, "r").each_line do |line|
    ips.push line
  end

  ips.each do |ip|
    expect(Ping.pingecho(ip, 5)).to eq true
  end
end
