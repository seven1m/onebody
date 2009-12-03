RAILS_ROOT = File.expand_path(__FILE__).match(/(.+)\/plugins/)[1] unless defined?(RAILS_ROOT)
require RAILS_ROOT + '/test/test_helper'

class AdminTest < ActiveSupport::TestCase
  
  should "know about associated reports" do
    @person = Person.forge(:admin => Admin.create)
    assert_equal [], @person.admin.reports.all
    @report = Report.create(:name => 'Foo', :active => true)
    @person.admin.reports << @report
    assert_equal [@report], @person.admin.reports.all
    assert_equal [@report], @person.admin.all_reports
  end
  
  should "know about unrestricted reports" do
    @person = Person.forge(:admin => Admin.create)
    assert_equal [], @person.admin.reports.all
    @report = Report.create(:name => 'Foo', :restricted => false, :active => true)
    assert_equal [], @person.admin.reports.all
    assert_equal [@report], @person.admin.all_reports
  end
  
end
