class BiblesController < ApplicationController
  
  before_filter :convert_reference_into_book_and_chapter, :only => %w(show)
  before_filter :get_filename,                            :only => %w(show)
  before_filter :redirect_to_normalized_url,              :only => %w(show)

  def show
    if params[:chapter].to_i == 0 and not request.xhr?
      redirect_to_complete_url
    else
      unless @chapter_filename
        respond_to do |format|
          error = 'The bible reference you provided could not be found. Please check the address and try again.'
          format.html { render :text => error, :layout => true, :status => 400 }
          format.js   { render(:update) { |p| p.alert(error) } }
        end
      end
    end
  end
  
  private
  
    def redirect_to_complete_url
      if params[:book] != 'x'
        book = Verse.normalize_book(params[:book]).downcase
        chapter = 1
      else
        book, chapter = Verse.random_book_and_chapter
      end
      redirect_to bible_path(:book => CGI.escape(book), :chapter => chapter)
    end

    def convert_reference_into_book_and_chapter
      if params[:reference].to_s =~ /(\d?[a-z]+)\s([\d\-,;\s]+)/i
        params[:book] = $1
        params[:chapter] = $2
      end
    end
  
    def get_filename
      params[:book].gsub!(/\+/, ' ')
      if @book = Verse.normalize_book(params[:book]) and  @chapter = params[:chapter].to_i
        @reference = "#{@book} #{@chapter}"
        @chapter_filename = "#{RAILS_ROOT}/app/views/bibles/#{@book}/#{'%03d' % @chapter}.erb"
        @chapter_filename = nil unless File.exists?(@chapter_filename)
      end
    end
    
    def redirect_to_normalized_url
      return unless @chapter_filename
      url_book = @book.downcase
      if url_book != params[:book]
        respond_to do |format|
          url = bible_path(:book => url_book, :chapter => params[:chapter])
          format.html { redirect_to url }
          format.js   { render(:update) { |p| p.redirect_to url } }
        end
      end
    end
    
    def feature_enabled?
      false # for now
    end

end
