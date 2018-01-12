SPECS:
=====================================
•Runs but below minimum specs: 80gb, 2.20ghz, 2gb ram

•Recomended specs: 300gb SSD, 4x 2.20 ghz and 12 gb ram

•Ultra specs: 300gb SSD, 4x 2.20 ghz and 96 gb ram (run the os in ram its self)

An open-source crypto currency exchange
=====================================

### Introduction 
   welcome to the most advanced peatio release available .also various UI and visual fixes have been added
   (more to come) and a market making system which will provide a trading partner for your users.
   please feel free to post issues and they will be handled rapidly.

### Recently done / News

•fix security issues

revert config/application.rb
revert config/initializers/pusher.rb
revert doc/deploy-production-server.md

•Multi Server Support https://github.com/scatterp/peatio/blob/master/MultiServerReadme.md

•To setup, just follow these steps (type these inside the console)
wget https://raw.githubusercontent.com/emnavalta/peatio/master/install1.sh
source install1.sh 

NOTE: it is critical you launch this with "SOURCE" not "SH" not "BASH" etc
NOTE2: less than 4GB of ram you should disable the line that reads bitcoind or you wont have enough memory to launch the page

•Merge in welcome page from coinxpro.com

### Todo (Coming soon in priority order)

•payment processing

•Investigate PoxA or socket.io as a pusher replacement

•all code has refactored 

•JRuby compatability and executes faster than previous versions at every step 

•FIX financial information exchange API  added to bring the support of the entire financial eco system allowing for trading clients banks etc to connect with the exchange


README in English
=====================================
Peatio is a free and open-source crypto currency exchange implementation with the Rails framework and other cutting-edge technology.

[README in ENGLISH](README-English.md)

README en Español
=======================================
**En traduccion**

Peatio es un software libre y open-source para la implementación de una Exchange de divisas

[README en Español](README-Español.md)
