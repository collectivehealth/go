require 'sinatra'
require 'sequel'
require 'sinatra/sequel'
require 'sinatra/respond_with'
require 'json'

class Link < Sequel::Model

  def self.search(query) 
    return self.filter(Sequel.like(:name, "#{query}%"))
               .or(Sequel.like(:url, "%#{query}%"))
               .order(Sequel.desc(:hits)).all
  end

  def hit!
    self.hits += 1
    self.save(:validate => false)
  end

  def validate
    super
    errors.add(:name, 'cannot be empty') if !name || name.empty?
    errors.add(:url, 'cannot be empty') if !url || url.empty?
  end

  def to_json
    {
      name: self.name,
      url: self.url,
      description: self.description,
      hits: self.hits,
    }
  end

end

class User < Sequel::Model

  def self.search(email)
    unless email.nil? || email.empty?
      email_id = email.split("@")[0]
      return self.where(email: email_id).first
    end
  end

  def validate
    super
    errors.add(:name, 'cannot be empty') if !name || name.empty?
    errors.add(:email, 'cannot be empty') if !email || email.empty?
  end

end


# Configuration

configure do
  set :erb, :escape_html => true
  set :public_folder, Proc.new { File.join(root, "static") }
end

# Actions

enable :sessions

get '/' do
  @links = Link.order(Sequel.desc(:hits)).all

  unless User.search(session[:id]).nil?
    params[:name] = User.search(session[:id]).name
  end

  respond_with :index do |f|
    f.html { erb :index, params: params }
    f.json { @links.map(&:to_json).to_json }
  end
end

get '/register/signup' do
  respond_with :register do |f|
    f.html { erb :register }
  end
end

post '/register' do
  if User.search(params[:email]).nil?
    clean_email = params[:email].strip.split("@")[0]
    begin
      user = User.create(
        :name => params[:name].strip,
        :email=> clean_email
      )
      session[:id] = clean_email
      redirect "/"
      rescue Sequel::UniqueConstraintViolation => e
        halt "Error: User already exists"
      end
  else
    puts "User already exists"
  end

end

get '/login' do 
  erb :login
end

post '/login' do
  halt "Login post doesn't exist yet"
  # if User.search(params[:email])
end

get '/links' do
  redirect '/'
end

post '/links' do
  begin
    Link.create(
      :name => params[:name].strip,
      :url  => params[:url].strip,
      :description  => params[:description].strip,
    )
    redirect '/'
  rescue Sequel::ValidationFailed,
         Sequel::DatabaseError => e
    halt "Error: #{e.message}"
  end
end

get '/links/search' do
  query = params[:q]
  @links = Link.search(query)

  respond_with :index do |f|
    f.html { erb :index, params: params }
    f.json { @links.map(&:to_json).to_json }
  end
end

post '/links/:id/remove' do
  link = Link.find(:id => params[:id])
  halt 404 unless link
  link.destroy
  redirect '/'
end

post '/links/:id/update' do
  link = Link.find(:id => params[:id])
  halt 404 unless link

  begin
    link.name = params[:name]
    link.description = params[:description]
    link.url = params[:url]
    link.save
    redirect '/'
  rescue Sequel::ValidationFailed,
         Sequel::DatabaseError => e
    halt "Error: #{e.message}"
  end
end

get '/:name/?*?' do
  link = Link[:name => [params[:name], params[:splat].first].join('/')]
  params[:splat] = [''] if link # remove the splat so we don't reuse it

  # Just try the straight link if we didn't find a matching link
  link ||= Link[:name => params[:name]]

  if link
    link.hit!

    parts = params[:splat].first.split('/')
    parts = nil if parts.empty?

    url = link.url
    url %= parts

    redirect url
  else
    # try to list sub-links of the namespace
    filtered_links = Link.search(params[:name])
    if filtered_links.empty?
      @links = Link.order(Sequel.desc(:hits)).all
      params[:not_found] = params[:name]
    else
      @links = filtered_links
      params[:links_filter] = params[:name]
    end
    respond_with :index do |f|
      f.html { erb(:index, params: params) }
    end
  end
end
