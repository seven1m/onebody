class Administration::LogosController < ApplicationController

  before_filter :only_admins

  def show
  end

  def create
    unless params[:file].to_s.blank?
      Site.current.logo = params[:file]
      Site.current.save!
    end
    redirect_to administration_logo_path
  end

  def destroy
    Site.current.logo = nil
    Site.current.save!
    redirect_to administration_logo_path
  end

  private

    def only_admins
      unless @logged_in.super_admin?
        render text: t('only_admins'), layout: true, status: 401
        return false
      end
    end

end
