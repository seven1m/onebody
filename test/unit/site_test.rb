require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActiveSupport::TestCase
  
  should "add settings" do
    start_count = Setting.count('*')
    new_site = Site.create(:name => 'Test', :host => 'testhost')
    assert new_site
    settings = get_settings_from_yaml
    assert_equal start_count + settings.length, Setting.count('*')
    settings.each do |fixture, values|
      next if values['section'] == 'URL' and values['name'] == 'Site' # set by Site model
      assert setting = Setting.find_by_site_id_and_section_and_name(new_site.id, values['section'], values['name'])
      assert_equal Setting.new(:value => values['value']).value.to_s, setting.value.to_s
    end
  end
  
  should "have sub tables" do
    # easiest way is to delete a site and see if the all the ":dependent => :destroy" stuff works
    Site.find(2).destroy_for_sure
  end
  
  should "add pages" do
    s = Site.create!(:name => 'testpages', :host => 'testpages')
    assert Page.connection.select_value("select count(*) from pages where site_id = #{s.id}").to_i > 3
  end
  
  private
    def get_settings_from_yaml
      YAML::load(File.open("#{Rails.root}/test/fixtures/settings.yml")).select do |fixture, values|
        values['site_id'].to_i == 1 if not values['global']
      end
    end
end
