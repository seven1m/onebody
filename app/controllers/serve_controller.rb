class ServeController < ApplicationController
  def index
    @ministries = Ministry.find :all, :order => 'name'
  end
  
  def view
    @ministry = Ministry.find params[:id]
  end
  
  def edit
    if params[:id]
      @ministry = Ministry.find params[:id]
    elsif @logged_in.admin?
      @ministry = Ministry.new :administrator => @logged_in
    end
    if @ministry and @logged_in.can_edit? @ministry
      if request.post?
        @ministry.update_attributes params[:ministry]
        if @ministry.errors.any?
          flash[:notice] = @ministry.errors.full_messages.join '; '
        else
          flash[:notice] = 'Changes saved.'
          redirect_to :action => 'view', :id => @ministry
        end
      end
    else
      render :text => 'You cannot edit this ministry.'
    end
  end
  
  def delete
    @ministry = Ministry.find params[:id]
    if @logged_in.can_edit? @ministry
      @ministry.destroy
    end
    redirect_to :action => 'index'
  end
  
  def add_servers
    @people = (session[:batch_people] ||= [])
    @dates = (session[:batch_dates] ||= [])
    @ministry = Ministry.find params[:id]
    @distributed = @dates.select { |d| d[:people] and d[:people].any? }.length > 0
    raise 'Error.' unless @logged_in.can_edit? @ministry
    if request.post?
      if params[:people]
        params[:people].each do |id|
          p = Person.find(id)
          session[:batch_people] << p unless session[:batch_people].include? p
        end
        flash[:notice] = 'The selected people have been added to the batch.'
      elsif params[:date] and params[:start_time] and params[:end_time]
        start_date = Time.parse(params[:date] + ' ' + params[:start_time]) rescue nil
        end_date = Time.parse(params[:date] + ' ' + params[:end_time]) rescue nil
        if start_date and end_date
          session[:batch_dates] << {:start => start_date, :end => end_date}
          flash[:notice] = 'The service date has been added.'
        else
          flash[:notice] = 'You did not enter the date and/or times in the right format.'
        end
      elsif params[:distribution] and @dates.any? and @people.any?
        if params[:distribution] == 'all'
          @dates.each do |date|
            date[:people] ||= []
            date[:people] << @people
            date[:people].flatten!
          end
        elsif params[:distribution] == 'spread'
          index = 0
          @people.each do |person|
            date = @dates[index]
            date[:people] ||= []
            date[:people] << person
            index += 1
            index = 0 if index >= @dates.length
          end
        end
        flash[:notice] = 'The servers have been distributed.'
      elsif params[:commit] and @people.any? and @dates.any?
        @dates.each do |date|
          if date[:people]
            date[:people].each do |person|
              remind_on = params[:reminder] ? Date.parse(date[:start].strftime('%Y-%m-%d')) - 7 : nil
              Worker.create(
                :ministry => @ministry,
                :person => person,
                :start => date[:start],
                :end => date[:end],
                :remind_on => remind_on
              )
            end
          end
        end
        session[:batch_people] = session[:batch_dates] = nil
        flash[:notice] = "You have successfully added #{@people.length} #{@people.length == 1 ? 'worker' : 'workers'} to #{@dates.length} #{@dates.length == 1 ? 'date' : 'dates'}."
        redirect_to :action => 'view', :id => @ministry
        return
      end
      redirect_to :action => 'add_servers', :id => @ministry
    end
  end
  
  def add_servers_simple
    @ministry = Ministry.find params[:id]
    if @logged_in.can_edit? @ministry and params[:people]
      start_time = Time.parse(params[:date] + ' ' + params[:start_time]) rescue nil
      end_time = Time.parse(params[:date] + ' ' + params[:end_time]) rescue nil
      if start_time and end_time
        remind_on = params[:reminder] ? Date.parse(start_time.strftime('%Y-%m-%d')) - 7 : nil
        params[:people].each do |id|
          @ministry.workers.create(
            :person => Person.find(id),
            :start => start_time,
            :end => end_time,
            :remind_on => remind_on
          )
        end
      end
    end
    redirect_to :action => 'view', :id => @ministry
  end
  
  def remove_person_from_batch
    session[:batch_people].delete(Person.find params[:person_id]) if session[:batch_people]
    redirect_to :action => 'add_servers', :id => params[:id]
  end
  
  def remove_date_from_batch
    date = {:start => Time.parse(params[:start]), :end => Time.parse(params[:end])}
    if session[:batch_dates]
      session[:batch_dates].select do |date|
        date[:start] == Time.parse(params[:start]) and date[:end] == Time.parse(params[:end])
      end.each { |d| session[:batch_dates].delete(d) }
    end
    redirect_to :action => 'add_servers', :id => params[:id]
  end
  
  def remove_people_from_dates_in_batch
    if session[:batch_dates]
      session[:batch_dates].each { |d| d[:people] = nil }
    end
    redirect_to :action => 'add_servers', :id => params[:id]
  end
  
  def clear_batch
    session[:batch_people] = session[:batch_dates] = nil
    redirect_to :action => 'add_servers', :id => params[:id]
  end
  
  def remove_worker
    @ministry = Ministry.find params[:id]
    @ministry.workers.find(params[:worker_id]).destroy
    redirect_to :action => 'view', :id => @ministry
  end
end
