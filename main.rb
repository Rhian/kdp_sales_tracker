require 'rubygems'
require 'watir-webdriver'
require 'json'
require 'sqlite3'
require 'haml'
require 'sinatra'
require 'data_mapper'

# Log in to Amazon and find latest json for sales reports

begin
	browser = Watir::Browser.new(:firefox)
	browser.goto('https://kdp.amazon.com/self-publishing/signin')

	browser.link(:class => 'new-signInButton').click
	browser.text_field(:name => "email").set(ARGV[0])
	browser.text_field(:name => "password").set(ARGV[1])
	browser.send_keys :enter
	browser.goto("https://kdp.amazon.com/self-publishing/reports/transactionReport?xxxxxxxxxx")
	browser.wait

	results = browser.text
	parsed_results = JSON.parse(results)

# Set up DataMapper model 

	DataMapper.setup(:default, 'sqlite3:amazon_data.db')

	class Sales
  	include DataMapper::Resource
  	property :id, Serial, :key => true
  	property :booktitles, String
  	property :booksales, Integer
	end

	DataMapper.auto_migrate!

# Update with parsed json from book title and sales column

	adapter = DataMapper.repository(:default).adapter

	  parsed_results["aaData"].each_with_index do |entry, i|
	  @output = entry[1].gsub(/<\/?[^>]*>/, "")
	  @output2 = entry[5]
	  adapter.execute('INSERT into Sales (booktitles,booksales) VALUES (?,?)', @output, @output2)
	  end

	DataMapper.auto_upgrade!

# Close browser

	browser.close
	rescue StandardError=>e
	  puts "Error: #{e}"
	end

# Define table that appears on index page

get '/' do
    @sales = Sales.all
    haml :index
end
