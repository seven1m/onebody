class PcSyncsController < ApplicationController

  # This has been adapted from a PHP script so that PowerChurch customers
  # can easily sync with OneBody servers without need for PHP running.

  def create
    if @logged_in and @logged_in.admin?(:import_data) and Site.current.import_export_enabled?
      sync_dir = File.join(Rails.root, 'tmp', 'pc_sync')
      FileUtils.mkdir_p(sync_dir)
      if (s = Sync.last).nil? or s.complete?
        @guid = params[:user_guid].scan(/[\-{}a-z0-9]/i).join # no funny business
        if Site.current.external_guid == @guid
          if params[:onebodysync]
            filename = File.join(sync_dir, "#{@guid}-#{Time.now.to_f.to_s}.zip")
            FileUtils.cp(params[:onebodysync].tempfile.path, filename)
            render :text => 'Process Complete'
          elsif params[:new_guid]
            @sync = Sync.new(:started_at => Time.now)
            @sync.person = @logged_in
            @sync.save!
            site = Site.current
            site.external_guid = Digest::SHA1.hexdigest("#{site.id}-#{@sync.created_at}-#{@sync.person.api_key}")
            site.save!
            system("#{File.expand_path("#{Rails.root}/script/rails runner")} -e #{Rails.env} \"Site.current = Site.find(#{Site.current.id}); Sync.find(#{@sync.id}).do_pc_sync('#{@guid}')\" &")
            render :text => "NEW PC_GUID = #{site.external_guid}"
          end
        else
          render :text => "TRANSACTION FAILED - external_guid DOES NOT MATCH\n" + \
                          "remote guid: #{Site.current.external_guid}\n" + \
                          "local guid: #{@guid}\n"
        end
      else
        render :text => 'ERROR: Sync already in progress.', :status => 500
      end
    else
      render :text => t('not_authorized'), :status => 401
    end
  end

  private

    def authenticate_user
      Person.logged_in = @logged_in = Person.find_by_api_key(params[:site_key])
    end

end
