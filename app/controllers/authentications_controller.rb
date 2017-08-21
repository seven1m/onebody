class AuthenticationsController < ApplicationController
  before_action :only_admins

  def create
    if person = Person.authenticate(params[:authentication][:email], params[:authentication][:password])
      render xml: person.to_xml(except: %w(salt encrypted_password feed_code api_key)), status: 201
    elsif person.nil?
      render plain: t('session.email_not_found'), status: 404
    else
      render plain: t('session.password_doesnt_match'), status: 401
    end
  end

  private

  def only_admins
    unless @logged_in.super_admin?
      render plain: t('only_admins'), layout: true, status: 400
      false
    end
  end
end
