class FeedsController < ApplicationController

  def index
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_edit?(@person)
        @feeds = @person.feeds.all
      else
        render :text => 'You are unauthorized to edit the feeds of this person.', :layout => true, :status => 401
      end
    elsif @logged_in.admin?(:edit_profiles)
      @feeds = Feed.all(
        :include => :person,
        :order => params[:order] == 'errors' ?
          'feeds.error_count desc' :
          'people.last_name, people.first_name, feeds.name'
      )
      render :action => 'index_for_all'
    else
      render :text => 'There was an error.', :layout => true, :status => 500
    end
  end

  def new
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      @feed = @person.feeds.new
    else
      render :text => 'You are unauthorized to edit the feeds of this person.', :layout => true, :status => 401
    end
  end
  
  def create
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person)
      if params[:type] == 'twitter' and params[:feed][:url] !~ /twitter\.com/
        params[:feed][:url] = "http://twitter.com/statuses/user_timeline.atom?screen_name=#{params[:feed][:url]}"
      end
      @feed = @person.feeds.new(params[:feed])
      if params[:final]
        if @feed.save
          if @feed.error_count.to_i > 0
            @feed.destroy; @feed = @person.feeds.new
            flash[:notice] = 'There was an error retrieving the feed. Please check the URL and try again.'
            render :action => 'new', :type => params[:type]
          else
            flash[:notice] = 'Success'
            redirect_to person_feeds_path(@person)
          end
        else
          render :action => 'new', :type => params[:type]
        end
      else
        url = Feed.transform_url(params[:feed][:url])
        feed = Feedzirra::Feed.fetch_and_parse(url) rescue nil
        @entries = feed.entries[0...Feed::IMPORT_LIMIT] rescue []
        if feed and @entries.to_a.any?
          render :action => 'preview'
        else
          render :text => 'No entries were found at the URL provided. Please go back and try again.', :layout => true, :status => 400
        end
      end
    else
      render :text => 'You are unauthorized to edit the feeds of this person.', :layout => true, :status => 401
    end
  end
  
  def destroy
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_edit?(@person)
        @person.feeds.find(params[:id]).destroy
        flash[:notice] = 'Feed deleted.'
        redirect_to person_feeds_path(@person)
      else
        render :text => 'You are unauthorized to edit the feeds of this person.', :layout => true, :status => 401
      end
    elsif @logged_in.admin?(:edit_profiles)
      Feed.find(params[:id]).destroy
      flash[:notice] = 'Feed deleted.'
      redirect_to feeds_path
    end
  end

end
