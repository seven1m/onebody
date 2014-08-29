class AddStreamItemForSites < ActiveRecord::Migration
  def change
    Site.each(&:create_as_stream_item) unless Rails.env.test?
  end
end
