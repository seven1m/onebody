class Administration::SyncsController < ApplicationController
  before_filter :only_admins

  VALID_SORT_COLS = %w(
    sync_items.syncable_type
    sync_items.name
    sync_items.legacy_id
    sync_items.operation
    sync_items.status
  )

  def index
    @syncs = Sync.order('created_at desc').page(params[:page])
  end

  def show
    unless params[:sort] and params[:sort].to_s.split(',').all? { |col| VALID_SORT_COLS.include?(col) }
      params[:sort] = 'sync_items.status,sync_items.name'
    end
    @sync = Sync.find(params[:id])
    @items = @sync.sync_items.order(params[:sort]).page(params[:page])
    @counts = @sync.count_items
  end

  # for api only
  def create
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      data = Hash.from_xml(request.body.read)['sync']
      @sync = Sync.new(data)
      @sync.person = @logged_in
      @sync.save!
      respond_to do |format|
        format.xml { render xml: @sync.to_xml }
      end
    else
      render text: t('not_authorized'), status: 401
    end
  end

  # for api only
  def update
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      @sync = Sync.find(params[:id])
      data = Hash.from_xml(request.body.read)['sync']
      @sync.update_attributes!(data)
      GroupMembershipsUpdateJob.perform_later(Site.current) if @sync.complete?
      respond_to do |format|
        format.xml { render xml: @sync.to_xml }
      end
    else
      render text: t('not_authorized'), status: 401
    end
  end

  # for api only
  def create_items
    if @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      @sync = Sync.find(params[:id])
      Hash.from_xml(request.body.read)['records'].to_a.each do |item|
        @sync.sync_items.create!(item)
      end
      respond_to do |format|
        format.xml { render xml: @sync.to_xml }
      end
    else
      render text: t('not_authorized'), status: 401
    end
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_sync)
      render text: t('only_admins'), layout: true, status: 401
      return false
    end
  end

end
