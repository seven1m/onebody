require File.dirname(__FILE__) + '/../test_helper'

class SiteTest < ActiveSupport::TestCase
  def test_settings_get_added
    start_count = Setting.count('*')
    new_site = Site.create(:name => 'Test', :host => 'testhost')
    assert new_site
    settings = get_settings_from_yaml
    assert_equal start_count + settings.length, Setting.count('*')
    settings.each do |fixture, values|
      assert setting = Setting.find_by_site_id_and_section_and_name(new_site.id, values['section'], values['name'])
      assert_equal Setting.new(:value => values['value']).value, setting.value
    end
  end
  
  def test_sub_tables
    assert !Site.sub_tables.include?('notifiers')
  end
  
  private
    def get_settings_from_yaml
      YAML::load(File.open(File.join(RAILS_ROOT, 'test/fixtures/settings.yml'))).select do |fixture, values|
        values['site_id'].to_i == 1 and not values['global']
      end
    end
end
