class Administration::ApiKeysController < ApplicationController
  before_filter :only_admins

  def show
    @key = @logged_in.api_key
  end

  def create
    @logged_in.generate_api_key
    @logged_in.save!
    redirect_to administration_api_key_path
  end

  def destroy
    @logged_in.api_key = nil
    @logged_in.save!
    redirect_to administration_api_key_path
  end

  private

    def only_admins
      unless @logged_in.super_admin?
        render text: t('application.api_access'), layout: true, status: 401
        return false
      end
    end

end
