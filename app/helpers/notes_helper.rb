module NotesHelper

  def render_note_body(note)
    sanitize_html(auto_link(note.body))
  end

end
