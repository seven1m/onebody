require File.dirname(__FILE__) + '/abstract_unit'

class ActsAsTaggableOnSteroidsTest < ActiveSupport::TestCase
  def test_find_related_tags_with
    assert_equivalent [tags(:good), tags(:bad), tags(:question)], Post.find_related_tags("nature")
    assert_equivalent [tags(:nature)], Post.find_related_tags([tags(:good)])
    assert_equivalent [tags(:bad), tags(:question)], Post.find_related_tags(["Very Good", "Nature"])        
    assert_equivalent [tags(:bad), tags(:question)], Post.find_related_tags([tags(:good), tags(:nature)])
  end
  
  def test_find_tagged_with_include_and_order
    assert_equal photos(:sam_sky, :sam_flower, :jonathan_dog),  Photo.find_tagged_with("Nature", :order => "photos.title DESC", :include => :user)
  end
  
  def test_find_related_tags_with_non_existent_tags
    assert_equal [], Post.find_related_tags("ABCDEFG")
    assert_equal [], Post.find_related_tags(['HIJKLM'])
  end
  
  def test_find_related_tags_with_nothing
    assert_equal [], Post.find_related_tags("")
    assert_equal [], Post.find_related_tags([])    
  end
    
  def test_find_tagged_with
    assert_equivalent [posts(:jonathan_sky), posts(:sam_flowers)], Post.find_tagged_with('"Very good"')
    assert_equal Post.find_tagged_with('"Very good"'), Post.find_tagged_with(['Very good'])
    assert_equal Post.find_tagged_with('"Very good"'), Post.find_tagged_with([tags(:good)])
    
    assert_equivalent [photos(:jonathan_dog), photos(:sam_flower), photos(:sam_sky)], Photo.find_tagged_with('Nature')
    assert_equal Photo.find_tagged_with('Nature'), Photo.find_tagged_with(['Nature'])
    assert_equal Photo.find_tagged_with('Nature'), Photo.find_tagged_with([tags(:nature)])
    
    assert_equivalent [photos(:jonathan_bad_cat), photos(:jonathan_dog), photos(:jonathan_questioning_dog)], Photo.find_tagged_with('"Crazy animal" Bad')
    assert_equal Photo.find_tagged_with('"Crazy animal" Bad'), Photo.find_tagged_with(['Crazy animal', 'Bad'])
    assert_equal Photo.find_tagged_with('"Crazy animal" Bad'), Photo.find_tagged_with([tags(:animal), tags(:bad)])
  end
  
  def test_find_tagged_with_nothing
    assert_equal [], Post.find_tagged_with("")
    assert_equal [], Post.find_tagged_with([])
  end
  
  def test_find_tagged_with_nonexistant_tags
    assert_equal [], Post.find_tagged_with('ABCDEFG')
    assert_equal [], Photo.find_tagged_with(['HIJKLM'])
    assert_equal [], Photo.find_tagged_with([Tag.new(:name => 'unsaved tag')])
  end
  
  def test_find_tagged_with_match_all
    assert_equivalent [photos(:jonathan_dog)], Photo.find_tagged_with('Crazy animal, "Nature"', :match_all => true)
  end
  
  def test_find_tagged_with_match_all_and_include
    assert_equivalent [posts(:jonathan_sky), posts(:sam_flowers)], Post.find_tagged_with(['Very good', 'Nature'], :match_all => true, :include => :tags)
  end
  
  def test_find_tagged_with_conditions
    assert_equal [], Post.find_tagged_with('"Very good", Nature', :conditions => '1=0')
  end
  
  def test_find_tagged_with_duplicates_options_hash
    options = { :conditions => '1=1' }.freeze
    assert_nothing_raised { Post.find_tagged_with("Nature", options) }
  end
  
  def test_find_tagged_with_exclusions
    assert_equivalent [photos(:jonathan_questioning_dog), photos(:jonathan_bad_cat)], Photo.find_tagged_with("Nature", :exclude => true)
    assert_equivalent [posts(:jonathan_grass), posts(:jonathan_rain), posts(:jonathan_cloudy), posts(:jonathan_still_cloudy)], Post.find_tagged_with("'Very good', Bad", :exclude => true)
  end
  
  def test_find_options_for_find_tagged_with_no_tags_returns_empty_hash
    assert_equal Hash.new, Post.find_options_for_find_tagged_with("")
    assert_equal Hash.new, Post.find_options_for_find_tagged_with([nil])
  end
  
  def test_find_options_for_find_tagged_with_leaves_arguments_unchanged
    original_tags = photos(:jonathan_questioning_dog).tags.dup
    Photo.find_options_for_find_tagged_with(photos(:jonathan_questioning_dog).tags)
    assert_equal original_tags, photos(:jonathan_questioning_dog).tags
  end
  
  def test_find_options_for_find_tagged_with_respects_custom_table_name
    Tagging.table_name = "categorisations"
    Tag.table_name = "categories"
    
    options = Photo.find_options_for_find_tagged_with("Hello")
    
    assert_no_match(/ taggings /, options[:joins])
    assert_no_match(/ tags /, options[:joins])
    
    assert_match(/ categorisations /, options[:joins])
    assert_match(/ categories /, options[:joins])
  ensure
    Tagging.table_name = "taggings"
    Tag.table_name = "tags"
  end
  
  def test_include_tags_on_find_tagged_with
    assert_nothing_raised do
      Photo.find_tagged_with('Nature', :include => :tags)
      Photo.find_tagged_with("Nature", :include => { :taggings => :tag })
    end
  end
  
  def test_basic_tag_counts_on_class
    assert_tag_counts Post.tag_counts, :good => 2, :nature => 7, :question => 1, :bad => 1
    assert_tag_counts Photo.tag_counts, :good => 1, :nature => 3, :question => 1, :bad => 1, :animal => 3
  end
  
  def test_tag_counts_on_class_with_date_conditions
    assert_tag_counts Post.tag_counts(:start_at => Date.new(2006, 8, 4)), :good => 1, :nature => 5, :question => 1, :bad => 1
    assert_tag_counts Post.tag_counts(:end_at => Date.new(2006, 8, 6)), :good => 1, :nature => 4, :question => 1
    assert_tag_counts Post.tag_counts(:start_at => Date.new(2006, 8, 5), :end_at => Date.new(2006, 8, 10)), :good => 1, :nature => 4, :bad => 1
    
    assert_tag_counts Photo.tag_counts(:start_at => Date.new(2006, 8, 12), :end_at => Date.new(2006, 8, 19)), :good => 1, :nature => 2, :bad => 1, :question => 1, :animal => 3
  end
  
  def test_tag_counts_on_class_with_frequencies
    assert_tag_counts Photo.tag_counts(:at_least => 2), :nature => 3, :animal => 3
    assert_tag_counts Photo.tag_counts(:at_most => 2), :good => 1, :question => 1, :bad => 1
  end
  
  def test_tag_counts_on_class_with_frequencies_and_conditions
    assert_tag_counts Photo.tag_counts(:at_least => 2, :conditions => '1=1'), :nature => 3, :animal => 3
  end
  
  def test_tag_counts_duplicates_options_hash
    options = { :at_least => 2, :conditions => '1=1' }.freeze
    assert_nothing_raised { Photo.tag_counts(options) }
  end
  
  def test_tag_counts_with_limit
    assert_equal 2, Photo.tag_counts(:limit => 2).size
    assert_equal 1, Post.tag_counts(:at_least => 4, :limit => 2).size
  end
  
  def test_tag_counts_with_limit_and_order
    assert_equal [tags(:nature), tags(:good)], Post.tag_counts(:order => 'count desc', :limit => 2)
  end
  
  def test_tag_counts_on_association
    assert_tag_counts users(:jonathan).posts.tag_counts, :good => 1, :nature => 5, :question => 1
    assert_tag_counts users(:sam).posts.tag_counts, :good => 1, :nature => 2, :bad => 1
    
    assert_tag_counts users(:jonathan).photos.tag_counts, :animal => 3, :nature => 1, :question => 1, :bad => 1
    assert_tag_counts users(:sam).photos.tag_counts, :nature => 2, :good => 1
  end
  
  def test_tag_counts_on_association_with_options
    assert_equal [], users(:jonathan).posts.tag_counts(:conditions => '1=0')
    assert_tag_counts users(:jonathan).posts.tag_counts(:at_most => 2), :good => 1, :question => 1
  end
  
  def test_tag_counts_on_has_many_through
    assert_tag_counts users(:jonathan).magazines.tag_counts, :good => 1
  end
  
  def test_tag_counts_on_model_instance
    assert_tag_counts photos(:jonathan_dog).tag_counts, :animal => 3, :nature => 3
  end
  
  def test_tag_counts_on_model_instance_merges_conditions
    assert_tag_counts photos(:jonathan_dog).tag_counts(:conditions => "tags.name = 'Crazy animal'"), :animal => 3
  end
  
  def test_tag_counts_on_model_instance_with_no_tags
    photo = Photo.create!
    
    assert_tag_counts photo.tag_counts, {}
  end
  
  def test_tag_counts_should_sanitize_scope_conditions
    Photo.send :with_scope, :find => { :conditions => ["tags.id = ?", tags(:animal).id] } do
      assert_tag_counts Photo.tag_counts, :animal => 3
    end
  end
  
  def test_tag_counts_respects_custom_table_names
    Tagging.table_name = "categorisations"
    Tag.table_name = "categories"
    
    options = Photo.find_options_for_tag_counts(:start_at => 2.weeks.ago, :end_at => Date.today)
    sql = options.values.join(' ')
    
    assert_no_match /taggings/, sql
    assert_no_match /tags/, sql
    
    assert_match /categorisations/, sql
    assert_match /categories/, sql
  ensure
    Tagging.table_name = "taggings"
    Tag.table_name = "tags"
  end
  
  def test_tag_list_reader
    assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    assert_equivalent ["Bad", "Crazy animal"], photos(:jonathan_bad_cat).tag_list
  end
  
  def test_reassign_tag_list
    assert_equivalent ["Nature", "Question"], posts(:jonathan_rain).tag_list
    posts(:jonathan_rain).taggings.reload
    
    # Only an update of the posts table should be executed, the other two queries are for savepoints
    assert_queries 3 do
      posts(:jonathan_rain).update_attributes!(:tag_list => posts(:jonathan_rain).tag_list.to_s)
    end
    
    assert_equivalent ["Nature", "Question"], posts(:jonathan_rain).tag_list
  end
  
  def test_new_tags
    assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    posts(:jonathan_sky).update_attributes!(:tag_list => "#{posts(:jonathan_sky).tag_list}, One, Two")
    assert_equivalent ["Very good", "Nature", "One", "Two"], posts(:jonathan_sky).tag_list
  end
  
  def test_remove_tag
    assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    posts(:jonathan_sky).update_attributes!(:tag_list => "Nature")
    assert_equivalent ["Nature"], posts(:jonathan_sky).tag_list
  end
  
  def test_change_case_of_tags
    original_tag_names = photos(:jonathan_questioning_dog).tag_list
    photos(:jonathan_questioning_dog).update_attributes!(:tag_list => photos(:jonathan_questioning_dog).tag_list.to_s.upcase)
    
    # The new tag list is not uppercase becuase the AR finders are not case-sensitive
    # and find the old tags when re-tagging with the uppercase tags.
    assert_equivalent original_tag_names, photos(:jonathan_questioning_dog).reload.tag_list
  end
  
  def test_remove_and_add_tag
    assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    posts(:jonathan_sky).update_attributes!(:tag_list => "Nature, Beautiful")
    assert_equivalent ["Nature", "Beautiful"], posts(:jonathan_sky).tag_list
  end
  
  def test_tags_not_saved_if_validation_fails
    assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    assert !posts(:jonathan_sky).update_attributes(:tag_list => "One, Two", :text => "")
    assert_equivalent ["Very good", "Nature"], Post.find(posts(:jonathan_sky).id).tag_list
  end
  
  def test_tag_list_accessors_on_new_record
    p = Post.new(:text => 'Test')
    
    assert p.tag_list.blank?
    p.tag_list = "One, Two"
    assert_equal "One, Two", p.tag_list.to_s
  end
  
  def test_clear_tag_list_with_nil
    p = photos(:jonathan_questioning_dog)
    
    assert !p.tag_list.blank?
    assert p.update_attributes(:tag_list => nil)
    assert p.tag_list.blank?
    
    assert p.reload.tag_list.blank?
  end
  
  def test_clear_tag_list_with_string
    p = photos(:jonathan_questioning_dog)
    
    assert !p.tag_list.blank?
    assert p.update_attributes(:tag_list => '  ')
    assert p.tag_list.blank?
    
    assert p.reload.tag_list.blank?
  end
  
  def test_tag_list_reset_on_reload
    p = photos(:jonathan_questioning_dog)
    assert !p.tag_list.blank?
    p.tag_list = nil
    assert p.tag_list.blank?
    assert !p.reload.tag_list.blank?
  end
  
  def test_instance_tag_counts
    assert_tag_counts posts(:jonathan_sky).tag_counts, :good => 2, :nature => 7
  end
  
  def test_tag_list_populated_when_cache_nil
    assert_nil posts(:jonathan_sky).cached_tag_list
    posts(:jonathan_sky).save!
    assert_equal posts(:jonathan_sky).tag_list.to_s, posts(:jonathan_sky).cached_tag_list
  end
  
  def test_cached_tag_list_used
    posts(:jonathan_sky).save!
    posts(:jonathan_sky).reload
    
    assert_no_queries do
      assert_equivalent ["Very good", "Nature"], posts(:jonathan_sky).tag_list
    end
  end
  
  def test_cached_tag_list_not_used
    # Load fixture and column information
    posts(:jonathan_sky).taggings(:reload)
    
    assert_queries 1 do
      # Tags association will be loaded
      posts(:jonathan_sky).tag_list
    end
  end
  
  def test_cached_tag_list_updated
    assert_nil posts(:jonathan_sky).cached_tag_list
    posts(:jonathan_sky).save!
    assert_equivalent ["Very good", "Nature"], TagList.from(posts(:jonathan_sky).cached_tag_list)
    posts(:jonathan_sky).update_attributes!(:tag_list => "None")
    
    assert_equal 'None', posts(:jonathan_sky).cached_tag_list
    assert_equal 'None', posts(:jonathan_sky).reload.cached_tag_list
  end
  
  def test_clearing_cached_tag_list
    # Generate the cached tag list
    posts(:jonathan_sky).save!
    
    posts(:jonathan_sky).update_attributes!(:tag_list => "")
    assert_equal "", posts(:jonathan_sky).cached_tag_list
  end

  def test_find_tagged_with_using_sti
    special_post = SpecialPost.create!(:text => "Test", :tag_list => "Random")
    
    assert_equal [special_post],  SpecialPost.find_tagged_with("Random")
    assert Post.find_tagged_with("Random").include?(special_post)
  end
  
  def test_tag_counts_using_sti
    SpecialPost.create!(:text => "Test", :tag_list => "Nature")
    
    assert_tag_counts SpecialPost.tag_counts, :nature => 1
  end
  
  def test_case_insensitivity
    assert_difference "Tag.count", 1 do
      Post.create!(:text => "Test", :tag_list => "one")
      Post.create!(:text => "Test", :tag_list => "One")
    end
    
    assert_equal Post.find_tagged_with("Nature"), Post.find_tagged_with("nature")
  end
  
  def test_tag_not_destroyed_when_unused
    posts(:jonathan_sky).tag_list.add("Random")
    posts(:jonathan_sky).save!
  
    assert_no_difference 'Tag.count' do
      posts(:jonathan_sky).tag_list.remove("Random")
      posts(:jonathan_sky).save!
    end
  end
  
  def test_tag_destroyed_when_unused
    Tag.destroy_unused = true
    
    posts(:jonathan_sky).tag_list.add("Random")
    posts(:jonathan_sky).save!
    
    assert_difference 'Tag.count', -1 do
      posts(:jonathan_sky).tag_list.remove("Random")
      posts(:jonathan_sky).save!
    end
  ensure
    Tag.destroy_unused = false
  end
end

class ActsAsTaggableOnSteroidsFormTest < ActiveSupport::TestCase
  include ActionView::Helpers::FormHelper
  
  def test_tag_list_contents
    fields_for :post, posts(:jonathan_sky) do |f|
      assert_match posts(:jonathan_sky).tag_list.to_s, f.text_field(:tag_list)
    end
  end
end
