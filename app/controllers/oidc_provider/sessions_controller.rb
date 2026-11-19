# frozen_string_literal: true

module OIDCProvider
  class SessionsController < ApplicationController
    before_action :require_authentication

    def destroy
      unauthenticate!
      return redirect_to '/' unless OIDCProvider.after_sign_out_path

      path = OIDCProvider.after_sign_out_path
      redirect_to(path.respond_to?(:call) ? path.call(params) : path)
    end
  end
end
