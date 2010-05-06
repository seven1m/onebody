class PodcastsController < ApplicationController

  def index
    @base_url = Setting.get(:services, :sermondrop_url).to_s.sub(/\/$/, '')
    unless @base_url.to_s.any?
      render :text => I18n.t('podcasts.not_configured'), :layout => true
    end
  end

end
