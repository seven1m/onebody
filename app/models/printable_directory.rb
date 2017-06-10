class PrintableDirectory
  def initialize(person, pictures: false)
    @person = person
    @pictures = pictures
    @pdf = Prawn::Document.new
  end

  attr_reader :person, :pictures

  delegate \
    :bounding_box,
    :bounds,
    :column_box,
    :cursor,
    :image,
    :move_down,
    :repeat,
    :start_new_page,
    :stroke_horizontal_rule,
    :text,
    to: :@pdf

  def render
    set_font
    render_cover_page
    start_new_page
    render_header
    render_families
    @pdf.render
  end

  private

  def set_font
    @pdf.font Rails.root.join('vendor/assets/fonts/OpenSans-Regular.ttf')
    @pdf.default_leading 3
  end

  def render_cover_page
    bounding_box [bounds.left, bounds.top / 2 + 100], width: bounds.width do
      text Setting.get(:name, :community),
           align: :center,
           size: 30
      text I18n.t('printable_directories.pdf.cover_page_sub_heading'),
           align: :center,
           size: 25
      move_down 200
      text I18n.t('printable_directories.pdf.created_for', name: person.name, date: Date.current.to_s(:date)),
           align: :center,
           size: 10
    end
  end

  def render_header
    repeat(->(pg) { pg > 1 }, dynamic: true) do
      bounding_box [bounds.left, bounds.top], width: bounds.width do
        text I18n.t('printable_directories.pdf.heading', community: Setting.get(:name, :community)),
             align: :center,
             size: 18
        stroke_horizontal_rule
      end
    end
  end

  FAMILY_MARGIN = 15

  def render_families
    @last_alpha = nil
    column_box [bounds.left, bounds.top - 50], width: bounds.width, height: bounds.height - 50, columns: 2 do
      families.each do |family|
        alpha = family.last_name[0].upcase
        photo = @pictures && family_photo(family)
        move_down cursor unless alpha_and_family_fits?(alpha, family, photo)
        if (alpha_heading = formatted_alpha_heading(alpha))
          text alpha_heading, inline_format: true
          stroke_horizontal_rule
          text "\n"
        end
        render_photo(photo) if @pictures
        text formatted_family(family), inline_format: true
        move_down FAMILY_MARGIN
        @last_alpha = alpha
      end
    end
  end

  PHOTO_MARGIN = 15

  def render_photo(photo)
    return unless photo
    image photo.path, width: image_bounds_width
    move_down PHOTO_MARGIN
  end

  def alpha_and_family_fits?(alpha, family, photo)
    trial = Prawn::Text::Formatted::Box.new(
      [{ text: formatted_alpha_and_family(alpha, family) }],
      at: [bounds.left, bounds.top],
      width: bounds.width,
      inline_format: true,
      document: @pdf
    )
    trial.render(dry_run: true)
    height = trial.height
    height += family_photo_height(photo) + PHOTO_MARGIN if photo
    cursor - height >= bounds.bottom
  end

  def formatted_alpha_and_family(alpha, family)
    [
      formatted_alpha_heading(alpha),
      formatted_family(family)
    ].compact.join("\n")
  end

  def formatted_alpha_heading(alpha)
    return if alpha == @last_alpha
    "<font size='20'>#{alpha}</font>\n"
  end

  def formatted_family(family)
    [
      "<font size='18'>#{h family.name}</font>",
      formatted_address(family),
      formatted_home_phone(family),
      family.people.undeleted.map do |p|
        [
          formatted_name(p, family),
          formatted_mobile_phone(p),
          formatted_email(p)
        ].compact.join(' · ')
      end
    ].flatten.compact.join("\n")
  end

  def formatted_address(family)
    return if family.pretty_address.blank?
    return unless family.people.undeleted.detect { |p| p.share_address_with(person) }
    "<font size='14'>#{h family.pretty_address.strip}</font>"
  end

  def formatted_home_phone(family)
    return if family.home_phone.blank?
    "<font size='14'>#{h format_phone(family.home_phone)}</font>"
  end

  def formatted_name(p, family)
    name = if p.last_name == family.last_name
             p.first_name
           else
             p.name
           end
    "<font size='12'>#{h name}</font>"
  end

  def formatted_mobile_phone(p)
    return unless p.show_attribute_to?(:mobile_phone, person)
    "<font size='10'>#{h format_phone(p.mobile_phone)}</font>"
  end

  def formatted_email(p)
    return unless p.show_attribute_to?(:email, person)
    "<font size='10'>#{h p.email}</font>"
  end

  def family_photo(family)
    path = if family.photo.present?
             family.photo.path(:large)
           elsif family.people.undeleted.size == 1
             family.people.undeleted.first.photo.presence.try(:path, :large)
            end
    return unless path && File.exist?(path)
    MiniMagick::Image.new(path)
  end

  def family_photo_height(photo)
    # (image_bounds_width / photo[:height] * photo[:width]).to_i
    (photo[:height] * image_bounds_width / photo[:width]).to_i
  end

  def image_bounds_width
    bounds.width * 0.6
  end

  def families
    Family.undeleted
          .has_printable_people
          .order('families.last_name, families.name, people.position')
          .includes(:people)
          .references(:people)
  end

  def format_phone(phone)
    ApplicationHelper.format_phone(phone)
  end

  def h(html)
    ERB::Util.h(html)
  end
end
