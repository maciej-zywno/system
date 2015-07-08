source 'https://rubygems.org'
ruby '2.2.2'

gem 'rails', '4.1.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'devise'
gem 'figaro'
gem 'haml-rails'
gem 'pg'
gem 'simple_form'
gem 'activerecord-import'
group :development do
  gem 'better_errors'
  gem 'binding_of_caller', :platforms=>[:mri_20]
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'html2haml'
  gem 'hub', :require=>nil
  gem 'quiet_assets'
  gem 'rails_layout'
  gem 'rb-fchange', :require=>false
  gem 'rb-fsevent', :require=>false
  gem 'rb-inotify', :require=>false
end
group :development, :test do
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem 'rspec-its'
end
group :production do
  gem 'unicorn'
end