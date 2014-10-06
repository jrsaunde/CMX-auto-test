CMX-auto-test
=============

This ia a quick tool that can be used to verify POST data coming from Meraki's CMX.

Esentially this server can be used to verify POSTs are being sent out from a network, along with which API version is being sent. 

The server is able to dynamically add and remove Push URLs via a web GUI, making life a little easier. 



Table of contents
=============

-[CMX auto test](#cmxauto)    
-[Table of contents](#table-of-contents)
-[Install](#install)   
-[Setting up a Server](#setup)    
-[How to use](#howto)    
-[Examples](#examples)    





Install
==============

To install you will need ruby. If you do not have ruby, please follow this link for installing ruby:
<a name="Installing Ruby on Linux" href="https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-on-ubuntu-12-04-lts-precise-pangolin-with-rvm">Installing Ruby on Linux</a>

Gems needed:
* sinatra
* sinatra-redirect-with-flash
* datamapper
* rack-flash3
* json
* sqlite3
* dm-sqlite-adapter 
* rack-google-analytics

You can install all of these with the following command:
```
gem install sinatra sinatra-redirect-with-flash datamapper rack-flash3 json sqlite3 dm-sqlite-adapter rack-google-analytics
```



Setting up a Server
===================
1. Clone repository
2. Copy the "sample-config.yml" file and rename it "config.yaml"
3. Edit the "config.yaml" file 
  1. Enter the hostname and port number you want to use for the push URLs
  2. Enter a secret, which will be used for validation
  3. Enter a Google Analytics tracker (not neccesary, but can be useful)
  4. Enter a http session token
4. To start the server, run the following command, substituting the IP address and port number you want to use:
```
ruby autocmx.rb -o <IP_ADDRESS> -p <PORT_NUMBER>
```

How to use
==========
1. Open a browser and go to http://HOSTNAME:PORT_NUMBER/
  1. Fill in your name, case number and validator from the test network
  2. Click "Add test!"
2. Add the push URL to the test network's dashboard
  1. Add the displayed push URL for you test to the test dashboard
  2. Select your API version (if applicable)
  3. Enter your secret
  4. Click the "Validate" button on dashboard
3. Wait a few minutes
4. Go back to http://HOSTNAME:PORT_NUMBER/
  1. Your test row should turn green when the server recieves POSTs from CMX
  2. It will display the received API version along, with a timestamp from the last POST it received
5. When you are done
  1. Remove your push URL from dashboard (the server will continue to receive POSTs until you remove the push URL)
  2. Click the delete button on the test server to have the server stop listening

Examples
========

