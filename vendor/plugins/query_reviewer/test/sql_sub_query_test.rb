require File.join(File.dirname(__FILE__), 'test_helper')

class SqlSubqueryTest < Test::Unit::TestCase
  def test_analyze_select_type
    query = get_query(:select_type => "DEPENDENT UNION")
    query.send :analyze_select_type!
    query.should_warn("DEPENDENT UNION", 2)
    
    query = get_query(:select_type => "UNCACHEABLE SUBQUERY")
    query.send :analyze_select_type!
    query.should_warn("UNCACHEABLE SUBQUERY", 10)
  end
  
  def get_query(options)
    SqlSubQuery.new(options)
  end
end
