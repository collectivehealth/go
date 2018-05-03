source 'https://rubygems.org'
ruby ">2.5"

gem 'rake'
gem 'sequel'
gem 'sinatra'
gem 'sinatra-sequel'
gem 'sinatra-contrib'
gem 'unicorn'

group :production do
  # Use Postgresql for ActiveRecord
  gem 'mysql2'
  gem 'pg'
end

group :development, :test do
  # Use SQLite for ActiveRecord
  gem 'sqlite3'
end
