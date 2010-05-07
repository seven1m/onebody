require File.dirname(__FILE__) + '/../test_helper'

class AdminTest < ActiveSupport::TestCase

  should "know about associated reports" do
    @person = Person.forge(:admin => Admin.create)
    assert_equal [], @person.admin.reports.all
    @report = Report.new(:name => 'Foo')
    @report.definition = Report::DEFAULT_DEFINITION['definition']
    @report.save
    @person.admin.reports << @report
    assert_equal [@report], @person.admin.reports.all
    assert_equal [@report], @person.admin.all_reports
  end

  should "know about unrestricted reports" do
    @person = Person.forge(:admin => Admin.create)
    assert_equal [], @person.admin.reports.all
    @report = Report.new(:name => 'Foo', :restricted => false)
    @report.definition = Report::DEFAULT_DEFINITION['definition']
    @report.save
    assert_equal [], @person.admin.reports.all
    assert_equal [@report], @person.admin.all_reports
  end

  context 'Privileges' do
    should "track available privileges" do
      assert Admin.privileges.include?('view_hidden_profiles')
    end

    should "add privileges" do
      Admin.add_privileges('foo')
      assert Admin.privileges.include?('foo')
    end
  end
end
