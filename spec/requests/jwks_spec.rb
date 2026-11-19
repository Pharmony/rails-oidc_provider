# frozen_string_literal: true

require 'rails_helper'

# RFC 7517 §5 requires a JWK Set to be a JSON object with a "keys" member
# whose value is an array of JWK objects — never a bare array of JWKs.
describe 'JWKS endpoint', type: :request do
  let(:url) { "#{test_server_url}/accounts/oauth/jwks.json" }
  let(:body) { response.parsed_body }

  before { get url }

  it 'returns a 200' do
    expect(response).to have_http_status(:ok)
  end

  it 'responds with application/json' do
    expect(response.media_type).to eq('application/json')
  end

  it 'responds with a JWK Set object (RFC 7517 §5), not a bare array' do
    expect(body).to be_a(Hash)
    expect(body).to have_key('keys')
    expect(body).not_to be_a(Array)
  end

  it 'exposes keys as a non-empty array of JWK objects' do
    expect(body['keys']).to be_an(Array)
    expect(body['keys']).not_to be_empty
    expect(body['keys']).to all(be_a(Hash))
  end

  it 'publishes the RSA public key parameters required for RS256 verification' do
    expect(body['keys']).to all(
      include(
        'kty' => 'RSA',
        'e' => a_kind_of(String),
        'n' => a_kind_of(String),
        'kid' => a_kind_of(String)
      )
    )
  end

  it 'does not expose private key material' do
    private_params = %w[d p q dp dq qi]

    body['keys'].each do |jwk|
      expect(jwk.keys & private_params).to be_empty
    end
  end
end
