# frozen_string_literal: true

module AuthHelpers
  def test_server_host
    ENV.fetch('APP_HOST', 'www.example.com')
  end

  def test_server_url
    "https://#{test_server_host}"
  end

  alias one_test_server_url test_server_url

  def create_user!(attrs = {})
    defaults = {
      email: "user-#{SecureRandom.hex(4)}@example.com",
      first_name: 'Jane',
      last_name: 'Doe'
    }
    User.create!(defaults.merge(attrs))
  end

  def login_as(user)
    post '/test_session', params: { user_id: user.id }
  end

  # Clear the session cookie without issuing a request that would overwrite
  # the example's `response` object (RSpec request specs keep the last response).
  def logout!
    return unless respond_to?(:cookies)

    jar = cookies
    jar.delete('user_id') if jar.respond_to?(:delete)
    # CookieStore session cookie name from dummy initializer
    %w[_dummy_session _session_id].each do |name|
      jar.delete(name) if jar.respond_to?(:delete)
    end
  end

  def login_and_logout_with_warden(attributes = nil)
    user =
      if attributes.is_a?(User)
        attributes
      elsif attributes.is_a?(Hash)
        create_user!(attributes)
      else
        create_user!
      end
    login_as(user)
    yield user
  ensure
    logout!
  end
end
