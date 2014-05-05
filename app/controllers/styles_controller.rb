class StylesController < ApplicationController

  skip_before_filter :authenticate_user, only: :show
  before_filter :only_admins, only: :edit

  def show
    if params[:browser] == 'ie'
      path = 'public/stylesheets/style.ie.scss'
    elsif params[:browser] == 'mobile'
      path = 'public/stylesheets/style.mobile.scss'
    else
      path = 'public/stylesheets/style.scss'
    end
    scss = File.read(Rails.root.join(path))
    if (color = Setting.get(:appearance, :theme_primary_color)).to_s.any?
      scss.sub!(/^\$primary: .+/, "$primary: ##{color};")
    end
    if (color = Setting.get(:appearance, :theme_secondary_color)).to_s.any?
      scss.sub!(/^\$secondary: .+/, "$secondary: ##{color};")
    end
    if (color = Setting.get(:appearance, :theme_top_color)).to_s.any?
      scss.sub!(/^\$common: .+/, "$common: ##{color};")
    end
    if (color = Setting.get(:appearance, :theme_nav_color)).to_s.any?
      scss.sub!(/^\$nav: .+/, "$nav: ##{color};")
    end
    css = Sass::Engine.new(
      scss,
      syntax: :scss,
      cache:  false,
      style:  :compressed
    ).render
    expires_in(1.year)
    render text: css, type: 'text/css'
  end

  def edit
    @primary   = Setting.get(:appearance, :theme_primary_color)
    @secondary = Setting.get(:appearance, :theme_secondary_color)
    @top       = Setting.get(:appearance, :theme_top_color)
    @nav       = Setting.get(:appearance, :theme_nav_color)
    @palettes_as_json = COLOR_PALETTES.inject({}) do |hash, palette|
      hash[palette.first] = palette.last
      hash
    end.to_json
  end

  def update
    if params[:primary]   =~ /[0-9A-F]{3,6}/i and \
       params[:secondary] =~ /[0-9A-F]{3,6}/i and \
       params[:top]       =~ /[0-9A-F]{3,6}/i and \
       params[:nav_color] =~ /[0-9A-F]{3,6}/i
      Setting.set(Site.current.id, 'Appearance', 'Theme Primary Color', params[:primary])
      Setting.set(Site.current.id, 'Appearance', 'Theme Secondary Color', params[:secondary])
      Setting.set(Site.current.id, 'Appearance', 'Theme Top Color', params[:top])
      Setting.set(Site.current.id, 'Appearance', 'Theme Nav Color', params[:nav_color])
      expire_fragment(%r{style(\.ie|\.mobile)?\?id=#{Site.current.id}})
    end
    redirect_to edit_style_path
  end

  private

    def only_admins
      unless @logged_in.super_admin?
        render text: t('admin.must_be_superadmin'), layout: true, status: 401
        return false
      end
    end

end
