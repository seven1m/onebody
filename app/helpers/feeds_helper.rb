module FeedsHelper
  def prayer_request_path(prayer_request)
    group_prayer_request_path(prayer_request.group, prayer_request)
  end
end
