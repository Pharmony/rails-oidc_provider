# frozen_string_literal: true

class TestSessionsController < ApplicationController
  skip_forgery_protection

  def create
    session[:user_id] = params.require(:user_id)
    head :ok
  end

  def destroy
    sign_out
    head :ok
  end
end
