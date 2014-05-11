class VersesController < ApplicationController

  def index
    if params[:person_id]
      @person = Person.find(params[:person_id])
      if @logged_in.can_see?(@person)
        @verses = @person.verses.paginate(order: 'created_at desc', page: params[:page])
      else
        render text: t('not_authorized'), layout: true, status: 401
      end
      # note: Tag.counts still accepts the :conditions option
      @tags = Verse.tag_counts(conditions: ['verses.id in (?)', @verses.map { |v| v.id } || [0]])
    else
      @verses = Verse.order(:book, :chapter, :verse) \
        .select('*, (select count(*) from people_verses where verse_id = verses.id) as people_count') \
        .page(params[:page])
      @tags = Verse.tag_counts
    end
  end

  def show
    @verse = Verse.find(params[:id])
  end

  def create
    id = params[:verse] ? params[:verse][:id] : params[:id]
    if @verse = Verse.find(id) rescue nil and @verse.valid?
      unless @verse.people.include? @logged_in
        @verse.people << @logged_in
        @verse.create_as_stream_item(@logged_in)
      end
      expire_fragment(%r{views/people/#{@logged_in.id}_})
      redirect_to params[:redirect_to] || @verse
    else
      render text: t('verses.not_found'), layout: true, status: 404
    end
  end

  def update
    @verse = Verse.find(params[:id])
    @verse.tag_list.remove(params[:remove_tag]) if params[:remove_tag]
    @verse.tag_list.add(*params[:add_tags].split) if params[:add_tags]
    @verse.save
    redirect_to @verse
  end

  def destroy
    @verse = Verse.find(params[:id])
    @verse.people.delete @logged_in
    @verse.delete_stream_items(@logged_in)
    expire_fragment(%r{views/people/#{@logged_in.id}_})
    unless @verse.people.count == 0
      redirect_to @verse
    else
      @verse.destroy
      redirect_to verses_path
    end
  end

end
