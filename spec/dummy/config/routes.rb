# frozen_string_literal: true

Rails.application.routes.draw do
  mount OIDCProvider::Engine, at: '/accounts/oauth'
  get '/.well-known/:id', to: 'oidc_provider/discovery#show'

  get '/signin', to: proc { |_env| [200, { 'Content-Type' => 'text/plain' }, ['sign in']] }

  post '/test_session', to: 'test_sessions#create'
  delete '/test_session', to: 'test_sessions#destroy'
end
