Rails.application.routes.draw do
  get '/providers', to: 'providers#index'
  post '/providers/lookup', to: 'providers#lookup'
  root 'providers#index'
end
