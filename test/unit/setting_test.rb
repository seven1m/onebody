require File.dirname(__FILE__) + '/../test_helper'

class SettingTest < ActiveSupport::TestCase

  context 'Field Types' do

    should "return an array for settings of type 'lines'" do
      Setting.set(1, 'Features', 'Custom Person Fields', ['Text', 'A Date'].join("\n"))
      assert_equal ['Text', 'A Date'], Setting.get(:features, :custom_person_fields)
      Setting.set(1, 'Features', 'Custom Person Fields', '')
    end

    should "return an array for settings of type 'lines', even if empty" do
      Setting.set(1, 'Features', 'Custom Person Fields', '')
      assert_equal [], Setting.get(:features, :custom_person_fields)
    end

  end

end
