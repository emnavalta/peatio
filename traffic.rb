require 'active_support'
require 'active_support/deprecation'
require 'net/http'
require 'json'
require 'peatio_client'
url = 'https://api.coinmarketcap.com/v1/ticker/?convert=ARS&limit=9'
uri = URI(url)
x = 2
until x==9 do
response = Net::HTTP.get(uri)
response = JSON.parse(response)
btc = response[0]["price_ars"].to_f
eth = response[1]["price_ars"].to_f
xrp = response[3]["price_ars"].to_f
bcc = response[4]["price_ars"].to_f
ltc = response[5]["price_ars"].to_f
anynumber=rand(0.1..5.0).round(2)
puts anynumber
client = PeatioAPI::Client.new access_key: '1kSXk6Bno2oM1tp6K1xvP5CGt6IyHutBQgFDAGOw', secret_key: 'xxbKDnEd3O3qISQITWTsXTwmX5ENT2EfWPj2GCi1', endpoint: 'http://127.0.0.1', timeout: 60
p client.post '/api/v2/orders', market: 'btcars', side: 'sell', volume: anynumber, price: btc
sleep(5)
p client.post '/api/v2/orders', market: 'btcars', side: 'buy', volume: anynumber, price: btc
anynumber=rand(0.1..5.0).round(2)
p client.post '/api/v2/orders', market: 'ethars', side: 'sell', volume: anynumber, price: eth
sleep(5)
p client.post '/api/v2/orders', market: 'ethars', side: 'buy', volume: anynumber, price: eth
anynumber=rand(0.1..5.0).round(2)
p client.post '/api/v2/orders', market: 'xrpars', side: 'sell', volume: anynumber, price: xrp
sleep(5)
p client.post '/api/v2/orders', market: 'xrpars', side: 'buy', volume: anynumber, price: xrp
anynumber=rand(0.1..5.0).round(2)
p client.post '/api/v2/orders', market: 'ltcars', side: 'sell', volume: anynumber, price: ltc
sleep(5)
p client.post '/api/v2/orders', market: 'ltcars', side: 'buy', volume: anynumber, price: ltc
anynumber=rand(0.1..5.0).round(2)
p client.post '/api/v2/orders', market: 'bccars', side: 'sell', volume: anynumber, price: bcc
sleep(5)
p client.post '/api/v2/orders', market: 'bccars', side: 'buy', volume: anynumber, price: bcc
p client.post '/api/v2/orders', market: 'bccars', side: 'buy', volume: anynumber, price: bcc
p client.post '/api/v2/orders/clear'
end
