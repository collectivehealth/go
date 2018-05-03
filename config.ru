require 'sequel'
require 'yaml'
require 'erb'

database_creds = YAML::load(ERB.new(File.read(File.join(File.dirname(__FILE__), 'config/database.yml'))).result)
database = database_creds[ENV["RACK_ENV"]]

Sequel.connect(database)

require './app'

run Sinatra::Application
