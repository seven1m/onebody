module NewsHelper
  def can_post_news?
    setting(:features, :news_page) && (
      setting(:features, :news_by_users) || @logged_in.admin?(:manage_news)
    )
  end
end
