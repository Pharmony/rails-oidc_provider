OIDCProvider::Engine.routes.draw do
  match 'authorizations' => 'authorizations#create', via: [:get, :post], as: :authorizations
  resource :user_info, only: :show
  get 'sessions/logout', to: 'sessions#destroy', as: :end_session

  post 'tokens', as: :tokens, to: proc { |env| OIDCProvider::TokenEndpoint.new.call(env) }
  # JSON::JWK::Set subclasses Array. Calling to_json on it can emit a bare
  # array; as_json returns the RFC 7517 §5 JWK Set object {"keys":[...]}.
  get 'jwks.json', as: :jwks, to: proc { |env| [200, {'Content-Type' => 'application/json'}, [OIDCProvider::IdToken.config[:jwk_set].as_json.to_json]] }
end
