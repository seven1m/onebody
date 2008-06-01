class MusicController < ApplicationController
  before_filter :only_admins, :only => ['edit', 'delete', 'add_attachment', 'delete_attachment']
  before_filter :check_access
  
  def index
    if params[:artists].to_s.any?
      conditions = ['artists like ?', "%#{params[:artists]}%"]
    else
      conditions = nil
    end
    @pages, @songs = paginate :songs, :order => 'title', :per_page => 25, :conditions => conditions
    biggest = Tag.find_by_sql("select count(tag_id) as num from songs_tags where song_id is not null group by tag_id order by count(tag_id) desc limit 1").first.num.to_i rescue 0
    # to get a range of point sizes between 8pt and 16pt,
    # figure a factor to multiply by the count
    # 1..11 + 9 (10..20)
    @factor = biggest / 11
    @factor = 1 if @factor.zero?
    @tags = Tag.find :all, :conditions => '(select count(*) from songs_tags where tag_id = tags.id and song_id is not null) > 0', :order => 'name'
    @setlists = Setlist.find :all, :conditions => "start >= #{sql_now}"
  end
  
  def view
    @song = Song.find params[:id]
  end
  
  def edit
    if params[:id]
      @song = Song.find params[:id]
    else
      @song = Song.new :person => @logged_in
    end
    if request.post?
      if @song.update_attributes params[:song]
        flash[:notice] = 'Song saved.'
        unless params[:id]
          flash[:notice] += ' Now you can attach your chord chart(s).'
        end
        redirect_to :action => 'edit', :id => @song
      else
        flash[:notice] = @song.errors.full_messages.join('; ')
      end
    end
  end
  
  def delete
    Song.find(params[:id]).destroy
    flash[:notice] = 'Song deleted.'
    redirect_to :action => 'index'
  end
  
  def amazon_search
    @products = Song.search(params[:song])[0..10]
    respond_to do |wants|
      wants.html { render :partial => 'amazon_search' }
      wants.js do
        render :update do |page|
          page.replace_html 'search_results', :partial => 'amazon_search'
        end
      end
    end
  end
  
  def amazon_grab
    product = nil
    if params[:song_amazon_asin].to_s.strip.empty?
      html = ''
    elsif product = Song.search(params[:song_amazon_asin])
      html = "<img src=\"#{product.image_url_medium}\"/>"
    else
      html = '<em>Amazon ASIN not found</em>'
    end
    respond_to do |wants|
      wants.html { render :inline => html }
      wants.js do
        render :update do |page|
          page.replace_html 'search_results', html
          if product
            page << "$('song_album').value = '#{quote(product.product_name)}';"
            page << "$('song_artists').value = '#{quote(product.artists.join(', '))}';"
          end
        end
      end
    end
  end
  
  def add_tags
    @song = Song.find params[:id]
    @song.tag_string = params[:tag_string]
    redirect_to :action => 'view', :id => @song
  end
  
  def delete_tag
    @song = Song.find params[:id]
    @song.tags.delete Tag.find(params[:tag_id])
    redirect_to :action => 'view', :id => @song
  end
  
  def add_attachment
    song = Song.find params[:id]
    attachment = song.attachments.create(
      :name => File.split(params[:file].original_filename.to_s).last,
      :file => params[:file].read,
      :content_type => params[:file].content_type.strip
    )
    if attachment.errors.any?
      flash[:notice] = attachments.errors.full_messages.join('; ')
    else
      flash[:notice] = 'Attachment saved.'
    end
    redirect_to :action => 'edit', :id => song
  end
  
  def delete_attachment
    attachment = Attachment.find params[:id]
    attachment.destroy
    flash[:notice] = 'Attachment deleted.'
    redirect_to :action => 'edit', :id => attachment.song
  end
  
  def view_attachment
    attachment = Attachment.find params[:id]
    unless attachment.song
      render :text => 'You are not authorized to view this attachment.', :layout => true
      return
    end
    # TODO: routes this file serve through regular web server
    send_data File.read(attachment.file_path), :filename => attachment.name, :type => attachment.content_type, :disposition => 'inline'
  end
  
  private
    def check_access
      unless @logged_in.admin?(:manage_music) or @logged_in.music_access?
        render :text => 'This section is only available to authorized users.', :layout => true
        return false
      end
    end
  
end
