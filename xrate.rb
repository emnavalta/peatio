require 'active_support'
require 'active_support/deprecation'
require 'net/http'
require 'json'
require 'peatio_client'
url = 'https://api.coinmarketcap.com/v1/ticker/?convert=ARS&limit=10'
uri = URI(url)
response = Net::HTTP.get(uri)
response = JSON.parse(response)
ars = response[0]["price_ars"].to_f
url = 'https://api.coinmarketcap.com/v1/ticker/?convert=EUR&limit=10'
uri = URI(url)
response = Net::HTTP.get(uri)
response = JSON.parse(response)
eur = response[0]["price_eur"].to_f
xrate = ars / eur
puts xrate
