class Administration::ApiClientsController < ApplicationController
  before_action :only_admins
  before_action :set_api_client, only: [:edit, :update, :destroy]

  def index
    @clients = Doorkeeper::Application.order(:name)
  end

  def new
    @client = Doorkeeper::Application.new
  end

  def create
    @client = Doorkeeper::Application.new(api_client_params)
    # redirect_uri is required by Doorkeeper but not used by us
    @client.redirect_uri = 'http://127.0.0.1'
    if @client.save
      redirect_to administration_api_clients_path,
                  notice: t('admin.api_clients.create.notice')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @client.update(api_client_params)
      redirect_to administration_api_clients_path,
                  notice: t('admin.api_clients.update.notice')
    else
      render :edit
    end
  end

  def destroy
    @client.destroy
    redirect_to administration_api_clients_path,
                notice: t('admin.api_clients.destroy.notice')
  end

  private

  def set_api_client
    @client = Doorkeeper::Application.find(params[:id])
  end

  def api_client_params
    params.require(:doorkeeper_application)
      .permit(:name)
  end
end