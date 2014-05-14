module NewsHelper

  def can_post_news?
    setting(:features, :news_page) and (
      setting(:features, :news_by_users) or @logged_in.admin?(:manage_news)
    )
  end

end
