class VersesController < ApplicationController
  def index
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_read?(@person)
        @verses = @person.verses.paginate(order: 'created_at desc', page: params[:page])
      else
        render html: t('not_authorized'), layout: true, status: 401
      end
      @tags = Verse.tag_counts(conditions: ['verses.id in (?)', @verses.map(&:id) || [0]], order: 'name')
    else
      @verses = Verse.order(:book, :chapter, :verse).with_people_count.page(params[:page])
      @tags = Verse.tag_counts(order: 'name')
    end
  end

  def show
    get_verse
  end

  def search
    @verse = Verse.find(params[:q])
    if @verse.invalid?
      render html: t('verses.not_found'), layout: true, status: 400
    else
      render partial: 'search_result'
    end
  rescue ActiveRecord::RecordNotFound
    render html: t('verses.not_found'), layout: true, status: 404
  end

  def create
    if get_verse
      unless @verse.people.include?(@logged_in)
        @verse.people << @logged_in
        @verse.create_as_stream_item(@logged_in)
      end
      redirect_to @verse
    end
  end

  def update
    @verse = Verse.find(params[:id])
    @verse.tag_list.remove(params[:remove_tag]) if params[:remove_tag]
    if params[:add_tags]
      add = params[:add_tags].split(/\s*,\s*|\s+/).map(&:downcase) - @verse.tag_list.map(&:downcase)
      @verse.tag_list.add(*add)
    end
    @verse.save
    respond_to do |format|
      format.html { redirect_to @verse }
      format.js
    end
  end

  def destroy
    @verse = Verse.find(params[:id])
    @verse.people.delete @logged_in
    @verse.delete_stream_items(@logged_in)
    expire_fragment(%r{views/people/#{@logged_in.id}_})
    if @verse.people.count == 0
      @verse.destroy
      redirect_to verses_path
    else
      redirect_to @verse
    end
  end

  private

  def get_verse
    @verse = Verse.find(params[:id])
    if @verse.try(:valid?)
      if params[:id] !~ /^\d+$/ && @verse.reference != params[:id]
        redirect_to verse_path(@verse.reference)
        return false
      end
      true
    elsif @verse && @verse.errors.any?
      add_errors_to_flash(@verse)
      redirect_to verses_path
      false
    else
      raise 'verse not found'
    end
  rescue
    render html: t('verses.not_found'), layout: true, status: 404
    false
  end
end
