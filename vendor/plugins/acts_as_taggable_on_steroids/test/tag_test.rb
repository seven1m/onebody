require File.dirname(__FILE__) + '/abstract_unit'

class TagTest < ActiveSupport::TestCase
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
    assert_equal Tag.find(tags(:good).id), Tag.find(tags(:good).id)
    assert_equal Tag.new(:name => 'A'), Tag.new(:name => 'A')
    assert_not_equal Tag.new(:name => 'A'), Tag.new(:name => 'B')
  end
  
  def test_taggings_removed_when_tag_destroyed
    assert_difference "Tagging.count", -Tagging.count(:conditions => { :tag_id => tags(:good).id }) do
      assert tags(:good).destroy
    end
  end
  
  def test_all_counts
    assert_tag_counts Tag.counts, :good => 4, :bad => 2, :nature => 10, :question => 2, :animal => 3
  end

  def test_all_counts_with_string_conditions
    assert_tag_counts Tag.counts(:conditions => 'taggings.created_at >= \'2006-08-15\''),
      :question => 1, :bad => 1, :animal => 1, :nature => 2, :good => 2
  end

  def test_all_counts_with_array_conditions
    assert_tag_counts Tag.counts(:conditions => ['taggings.created_at >= ?', '2006-08-15']),
      :question => 1, :bad => 1, :animal => 1, :nature => 2, :good => 2
  end

  def test_all_counts_with_hash_conditions
    tag_counts = Tag.counts(
      :conditions => {
        :taggings => { :created_at => (DateTime.parse('2006-08-14 23:59') .. DateTime.parse('4000-01-01')) }
      }
    )
    
    assert_tag_counts tag_counts, :question => 1, :bad => 1, :animal => 1, :nature => 2, :good => 2
  end
end
