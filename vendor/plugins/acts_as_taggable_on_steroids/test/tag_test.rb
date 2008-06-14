require File.dirname(__FILE__) + '/abstract_unit'

class TagTest < Test::Unit::TestCase
  fixtures :tags, :taggings, :users, :photos, :posts
  
  def test_name_required
    t = Tag.create
    assert_match /blank/, t.errors[:name].to_s
  end
  
  def test_name_unique
    t = Tag.create!(:name => "My tag")
    duplicate = t.clone
    
    assert !duplicate.save
    assert_match /taken/, duplicate.errors[:name].to_s
  end
  
  def test_taggings
    assert_equivalent [taggings(:jonathan_sky_good), taggings(:sam_flowers_good), taggings(:sam_flower_good), taggings(:ruby_good)], tags(:good).taggings
    assert_equivalent [taggings(:sam_ground_bad), taggings(:jonathan_bad_cat_bad)], tags(:bad).taggings
  end
  
  def test_to_s
    assert_equal tags(:good).name, tags(:good).to_s
  end
  
  def test_equality
    assert_equal tags(:good), tags(:good)
    assert_equal Tag.find(1), Tag.find(1)
    assert_equal Tag.new(:name => 'A'), Tag.new(:name => 'A')
    assert_not_equal Tag.new(:name => 'A'), Tag.new(:name => 'B')
  end
end
