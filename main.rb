require 'rubygems'
require 'mechanize'
require 'json'
require 'sqlite3'
require 'haml'
require 'sinatra'

# use Mechanize gem to log into Amazon and set cookies

agent = Mechanize.new
page  = agent.get('https://kdp.amazon.com/self-publishing/signin')
inner_page = page.link_with(:dom_class => 'new-signInButton').click

form = inner_page.forms.first

form.email = ARGV[0]
form.password = ARGV[1]

inner_page = agent.submit(form)

scraper = Mechanize.new
agent.cookies.each do |cookie|
    scraper.cookie_jar.add!(cookie)
end

# Parse json, set up db and write the two columns we need to table after stripping tags etc

# This will be rewritten using DataMapper

url = "https://kdp.amazon.com/self-publishing/reports/transactionReport?_=xxxxxxx&previousMonthReports=false&marketplaceID=xxxxxxx"

response = scraper.get(url)
results = JSON.parse(response.body)

DB = SQLite3::Database.open( "amazon_data" )

DB.execute "DROP TABLE IF EXISTS sales_table"
DB.execute( "create table sales_table (id INTEGER PRIMARY KEY AUTOINCREMENT, books VARCHAR, figures
VARCHAR);" )

op = DB.prepare("INSERT into sales_table (books,figures) VALUES (?,?)")

  results["aaData"].each_with_index do |entry, i|
  @output = entry[1].gsub(/<\/?[^>]*>/, "")
  @output2 = entry[3]
  if results != nil
  op.execute(@output,@output2)
  end
end

# Simple front end display 

get '/' do
  haml :index
end

post '/statistics' do
  haml :statistics
  @booktitles = DB.execute( "select books from sales_table" )
  @booksales = DB.execute( "select figures from sales_table" )
end


