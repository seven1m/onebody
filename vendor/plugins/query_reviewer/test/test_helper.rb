require "rubygems"
require "activesupport"
require 'test/unit'
require "query_reviewer"

module QueryReviewer
  class SqlSubQuery
    include Test::Unit::Assertions
    def should_warn(problem, severity = nil)
      assert self.warnings.detect{|warn| warn.problem.downcase == problem.downcase && 
        (!severity || warn.severity == severity)}
    end
  end
end

class Test::Unit::TestCase
  include QueryReviewer
end
