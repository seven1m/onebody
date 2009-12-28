require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < ActiveSupport::TestCase
  
  should "delete admin associations if changed to unrestricted" do
    @report = Report.create(:name => 'Foo', :restricted => true, :definition => {'collection' => 'people', 'selector' => []})
    @report.admins.create
    assert_equal 1, @report.admins.count
    @report.name = 'Bar'
    @report.save
    assert_equal 1, @report.admins.count
    @report.restricted = false
    @report.save
    assert_equal 0, @report.admins.count
  end
  
  context 'Selector Form Conversion (To)' do
  
    setup do
      Person.send_to_mongo
      @report = Report.new(:name => 'Foo')
      @report.definition = {'collection' => 'people'}
    end
    
    should "convert =" do
      @report.definition['selector'] = {'gender' => 'Male'}
      assert_equal [['gender', '=', 'Male']], @report.selector_for_form
    end
    
    should "convert true/false" do
      @report.definition['selector'] = {'child' => true}
      assert_equal [['child', '=', true]], @report.selector_for_form
      @report.definition['selector'] = {'child' => false}
      assert_equal [['child', '=', false]], @report.selector_for_form
    end
    
    should "convert $lt" do
      @report.definition['selector'] = {'birthday' => {'$lt' => '1981-04-28'}}
      assert_equal [['birthday', '$lt', '1981-04-28']], @report.selector_for_form
    end
    
    should "convert $lte" do
      @report.definition['selector'] = {'birthday' => {'$lte' => '1981-04-28'}}
      assert_equal [['birthday', '$lte', '1981-04-28']], @report.selector_for_form
    end
    
    should "convert $gt" do
      @report.definition['selector'] = {'birthday' => {'$gt' => '1981-04-28'}}
      assert_equal [['birthday', '$gt', '1981-04-28']], @report.selector_for_form
    end
    
    should "convert $gte" do
      @report.definition['selector'] = {'birthday' => {'$gte' => '1981-04-28'}}
      assert_equal [['birthday', '$gte', '1981-04-28']], @report.selector_for_form
    end
    
    should "convert $ne" do
      @report.definition['selector'] = {'admin_id' => {'$ne' => 1}}
      assert_equal [['admin_id', '$ne', 1]], @report.selector_for_form
    end
    
    should "convert $in" do
      @report.definition['selector'] = {'admin_id' => {'$in' => [1,7]}}
      assert_equal [['admin_id', '$in', '1|7']], @report.selector_for_form
    end
    
    should "convert $nin" do
      @report.definition['selector'] = {'admin_id' => {'$nin' => [1,7]}}
      assert_equal [['admin_id', '$nin', '1|7']], @report.selector_for_form
    end
    
    should "convert $nil" do
      @report.definition['selector'] = {'gender' => nil}
      assert_equal [['gender', '$nil']], @report.selector_for_form
    end
    
    should "convert $nnil" do
      @report.definition['selector'] = {'gender' => {'$ne' => nil}}
      assert_equal [['gender', '$nnil']], @report.selector_for_form
    end
    
    should "convert =~" do
      @report.definition['selector'] = {'gender' => /Male/}
      assert_equal [['gender', '=~', 'Male']], @report.selector_for_form
    end
    
    should "convert =~i" do
      @report.definition['selector'] = {'gender' => /male/i}
      assert_equal [['gender', '=~i', 'male']], @report.selector_for_form
    end
    
    should "convert $or and $and" do
      @report.definition['selector'] = {'$or' => {'gender' => 'Female', 'child' => true}}
      assert_equal [['$or', [['child', '=', true], ['gender', '=', 'Female']]]], @report.selector_for_form
      @report.definition['selector'] = {'$or' => {'gender' => 'Female', '$and' => {'gender' => 'Male', 'child' => true}}}
      assert_equal [['$or', [['$and', [['child', '=', true], ['gender', '=', 'Male']]], ['gender', '=', 'Female']]]], @report.selector_for_form
      @report.definition['selector'] = {'gender' => 'Female', '$or' => {'gender' => 'Male', 'child' => true}}
      assert_equal [['$or', [['child', '=', true], ['gender', '=', 'Male']]], ['gender', '=', 'Female']], @report.selector_for_form, @report.selector_for_form
    end
  
  end
  
  context 'Selector Form Conversion (From)' do
  
    setup do
      Person.send_to_mongo
      @report = Report.new(:name => 'Foo')
      @report.definition = {'collection' => 'people'}
    end
    
    should "convert =" do
      @report.selector = {:field => ['gender'], :operator => ['='], :value => ['Male']}
      assert_equal({'gender' => 'Male'}, @report.definition['selector'])
    end
    
    should "convert true/false" do
      @report.selector = {:field => ['child'], :operator => ['='], :value => ['true']}
      assert_equal({'child' => true}, @report.definition['selector'])
      @report.selector = {:field => ['child'], :operator => ['='], :value => ['false']}
      assert_equal({'child' => false}, @report.definition['selector'])
    end
    
    should "convert $lt" do
      @report.selector = {:field => ['birthday'], :operator => ['$lt'], :value => ['1981-04-28']}
      assert_equal({'birthday' => {'$lt' => '1981-04-28'}}, @report.definition['selector'])
    end
    
    should "convert $lte" do
      @report.selector = {:field => ['birthday'], :operator => ['$lte'], :value => ['1981-04-28']}
      assert_equal({'birthday' => {'$lte' => '1981-04-28'}}, @report.definition['selector'])
    end
    
    should "convert $gt" do
      @report.selector = {:field => ['birthday'], :operator => ['$gt'], :value => ['1981-04-28']}
      assert_equal({'birthday' => {'$gt' => '1981-04-28'}}, @report.definition['selector'])
    end
    
    should "convert $gte" do
      @report.selector = {:field => ['birthday'], :operator => ['$gte'], :value => ['1981-04-28']}
      assert_equal({'birthday' => {'$gte' => '1981-04-28'}}, @report.definition['selector'])
    end
    
    should "convert $ne" do
      @report.selector = {:field => ['admin_id'], :operator => ['$ne'], :value => ['1']}
      assert_equal({'admin_id' => {'$ne' => 1}}, @report.definition['selector'])
    end
    
    should "convert $in" do
      @report.selector = {:field => ['admin_id'], :operator => ['$in'], :value => ['1|7']}
      assert_equal({'admin_id' => {'$in' => [1,7]}}, @report.definition['selector'])
    end
    
    should "convert $nin" do
      @report.selector = {:field => ['admin_id'], :operator => ['$nin'], :value => ['1|7']}
      assert_equal({'admin_id' => {'$nin' => [1,7]}}, @report.definition['selector'])
    end
    
    should "convert $nil" do
      @report.selector = {:field => ['gender'], :operator => ['$nil'], :value => ['']}
      assert_equal({'gender' => nil}, @report.definition['selector'])
    end
    
    should "convert $nnil" do
      @report.selector = {:field => ['gender'], :operator => ['$nnil'], :value => ['']}
      assert_equal({'gender' => {'$ne' => nil}}, @report.definition['selector'])
    end
    
    should "convert =~" do
      @report.selector = {:field => ['gender'], :operator => ['=~'], :value => ['Male']}
      assert_equal({'gender' => /Male/}, @report.definition['selector'])
    end
    
    should "convert =~i" do
      @report.selector = {:field => ['gender'], :operator => ['=~i'], :value => ['male']}
      assert_equal({'gender' => /male/i}, @report.definition['selector'])
    end
  
  end
  
  context 'JavaScript Function Generation' do
  
    setup do
      Person.send_to_mongo
      @report = Report.new(:name => 'Foo')
      @report.definition = {'collection' => 'people'}
    end
    
    should "generate from = operator" do
      @report.definition['selector'] = [['$and', [['gender', '=', 'Male']]]]
      assert_equal 'return (this.gender == "Male");', @report.selector_to_javascript
    end
    
    should "generate from boolean value" do
      @report.definition['selector'] = [['$and', [['elder', '=', true]]]]
      assert_equal 'return (this.elder == true);', @report.selector_to_javascript
      @report.definition['selector'] = [['$and', [['elder', '=', false]]]]
      assert_equal 'return (this.elder == false);', @report.selector_to_javascript
    end
    
    should "generate from $lt operator" do
      @report.definition['selector'] = [['$and', [['birthday', '$lt', '1981-04-28']]]]
      assert_equal 'return (this.birthday < "1981-04-28");', @report.selector_to_javascript
    end
    
    should "generate from $lte operator" do
      @report.definition['selector'] = [['$and', [['birthday', '$lte', '1981-04-28']]]]
      assert_equal 'return (this.birthday <= "1981-04-28");', @report.selector_to_javascript
    end
    
    should "generate from $gt operator" do
      @report.definition['selector'] = [['$and', [['birthday', '$gt', '1981-04-28']]]]
      assert_equal 'return (this.birthday > "1981-04-28");', @report.selector_to_javascript
    end
    
    should "generate from $gte operator" do
      @report.definition['selector'] = [['$and', [['birthday', '$gte', '1981-04-28']]]]
      assert_equal 'return (this.birthday >= "1981-04-28");', @report.selector_to_javascript
    end
    
    should "geneate from $ne operator" do
      @report.definition['selector'] = [['$and', [['admin_id', '$ne', 1]]]]
      assert_equal 'return (this.admin_id != 1);', @report.selector_to_javascript
    end
    
    should "generate from $in operator" do
      @report.definition['selector'] = [['$and', [['admin_id', '$in', [1, 7]]]]]
      assert_equal 'return ([1, 7].indexOf(this.admin_id) > -1);', @report.selector_to_javascript
    end
    
    should "generate from $nil operator" do
      @report.definition['selector'] = [['$and', [['gender', '$nil']]]]
      assert_equal 'return (this.gender == null);', @report.selector_to_javascript
    end
    
    should "generate from $nnil operator" do
      @report.definition['selector'] = [['$and', [['gender', '$nnil']]]]
      assert_equal 'return (this.gender != null);', @report.selector_to_javascript
    end
    
    should "generate from =~ operator" do
      @report.definition['selector'] = [['$and', [['gender', '=~', /Male/]]]]
      assert_equal 'return ((this.gender && this.gender.match(/Male/)));', @report.selector_to_javascript
    end
    
    should "generate from =~i operator" do
      @report.definition['selector'] = [['$and', [['gender', '=~i', /male/i]]]]
      assert_equal 'return ((this.gender && this.gender.match(/male/i)));', @report.selector_to_javascript
    end
    
    should "generate from multiple selectors" do
      # and
      @report.definition['selector'] = [['$and', [['admin_id', '$in', [1, 7]], ['gender', '=', 'Male'], ['first_name', '=~i', /a/i], ['suffix', '$nil']]]]
      assert_equal 'return ([1, 7].indexOf(this.admin_id) > -1 && this.gender == "Male" && (this.first_name && this.first_name.match(/a/i)) && this.suffix == null);', @report.selector_to_javascript
      # or
      @report.definition['selector'] = [['$or', [['admin_id', '$in', [1, 7]], ['gender', '=', 'Male'], ['first_name', '=~i', /a/i], ['suffix', '$nil']]]]
      assert_equal 'return ([1, 7].indexOf(this.admin_id) > -1 || this.gender == "Male" || (this.first_name && this.first_name.match(/a/i)) || this.suffix == null);', @report.selector_to_javascript
      # nested or/and
      @report.definition['selector'] = [['$and', [['$or', [['admin_id', '$in', [1, 7]], ['first_name', '=~i', /a/i]]], ['gender', '=', 'Male'], ['suffix', '$nil']]]]
      assert_equal 'return (([1, 7].indexOf(this.admin_id) > -1 || (this.first_name && this.first_name.match(/a/i))) && this.gender == "Male" && this.suffix == null);', @report.selector_to_javascript
    end
    
    should "generate from embedded-document selectors" do
      # singular embedded document (not really different from normal selectors)
      @report.definition['selector'] = [['$and', [['admin.flags', '=~', /view_hidden_profiles/]]]]
      assert_equal 'return ((this.admin.flags && this.admin.flags.match(/view_hidden_profiles/)));', @report.selector_to_javascript
      # embedded document inside an array (requires our 'select' function)
      @report.definition['selector'] = [['$and', [['groups.name', '=', 'Van Drivers']]]]
      assert_equal 'return (select(this.groups, function(i){ return i.name == "Van Drivers" }).length > 0);', @report.selector_to_javascript
      # a singular embedded document on a document inside an array (whew!)
      @report.definition['selector'] = [['$and', [['groups.membership.get_email', '=', true]]]]
      assert_equal 'return (select(this.groups, function(i){ return i.membership.get_email == true }).length > 0);', @report.selector_to_javascript
    end
  
  end
  
  context 'Execution' do
  
    setup do
      Person.send_to_mongo
      @report = Report.new(:name => 'Foo')
      @report.definition = {'collection' => 'people'}
    end
    
    should "return results by a single field" do
      @report.definition['selector'] = [['$and', [['gender', '=', 'Male']]]]
      results = @report.run
      actual = Person.count('*', :conditions => {:gender => 'Male'})
      assert_equal actual, results.count
    end
    
    should "return results by multiple fields" do
      @report.definition['selector'] = [['$and', [['gender', '=', 'Female'], ['first_name', '=', 'Jennie']]]]
      results = @report.run
      assert_equal 1, results.count
      assert_equal 'Jennie', results.first['first_name']
    end
    
    should "return results by nested fields" do
      @report.definition['selector'] = [['$and', [['groups.name', '=', 'College Group']]]]
      results = @report.run
      assert_equal 2, results.count
    end
    
    should "return results by regular expression" do
      @report.definition['selector'] = [['$and', [['birthday', '=~', /^1980\-06\-24/]]]]
      results = @report.run
      assert_equal 2, results.count
      assert results.all? { |p| %w(Jennie Jane).include?(p['first_name']) }
    end
    
    should "return results by relative expression" do
      @report.definition['selector'] = [['$and', [['birthday', '$gte', '2006-01-01']]]]
      results = @report.run
      assert_equal 2, results.count
      assert results.all? { |p| %w(Mac Megan).include?(p['first_name']) }
    end
    
    should "return results by multiple relative expressions" do
      @report.definition['selector'] = [['$and', [['birthday', '$gte', '2006-01-01'], ['birthday', '$lt', '2006-11-03']]]]
      results = @report.run
      assert_equal 1, results.count
      assert_equal 'Megan', results.first['first_name']
    end

  end
    
end
