require_relative '../../test_helper'

class NestedResourceConcernTest < ActionController::TestCase

  # a very fake controller for testing our mixin
  class BaseController
    attr_accessor :params
    include NestedResourceConcern

    def initialize(params={})
      @params = params
    end

    def action(name)
      params[:action] = name
      self.class.filters.each { |f| send(f) }
      send(name) if respond_to?(name)
    end

    class_attribute :filters
    def self.before_filter(filter, options={})
      self.filters ||= []
      self.filters << filter
    end

    def self.prepend_before_filter(filter, options={})
      self.filters ||= []
      self.filters.unshift filter
    end

    def assigns
      instance_variables.each_with_object({}) do |name, hash|
        hash[name.to_s.sub('@', '').to_sym] = instance_variable_get(name)
      end
    end

    def controller_name
      self.class.controller_name
    end

    def self.controller_name
      name.demodulize.sub(/Controller$/, '').underscore
    end
  end

  context 'given a NotesController' do
    setup do
      NotesController = Class.new(BaseController)
    end

    context 'load a single parent' do
      setup do
        @group = FactoryGirl.create(:group)
        NotesController.class_eval do
          load_parent :group
        end
      end

      context 'when called with the parent id' do
        setup do
          @controller = NotesController.new(group_id: @group.id)
          @controller.action(:index)
        end

        should 'set parent resource by name' do
          assert_equal @group, @controller.assigns[:group]
        end

        should 'set parent resource under @parent' do
          assert_equal @group, @controller.assigns[:parent]
        end

        should 'define child accessor' do
          assert_instance_of ActiveRecord::Relation, @controller.send(:notes)
        end
      end

      context 'when called without the parent id' do
        should 'raise exception' do
          assert_raise(ActionController::ParameterMissing) do
            NotesController.new.action(:index)
          end
        end
      end
    end

    context 'load more than one parent' do
      setup do
        @group = FactoryGirl.create(:group)
        @person = FactoryGirl.create(:person)
        NotesController.class_eval do
          load_parent :group, :person
        end
      end

      context 'when called with the first parent id' do
        setup do
          @controller = NotesController.new(group_id: @group.id)
          @controller.action(:index)
        end

        should 'set parent resource' do
          assert_equal @group, @controller.assigns[:group]
        end
      end

      context 'when called with the second parent id' do
        setup do
          @controller = NotesController.new(person_id: @person.id)
          @controller.action(:index)
        end

        should 'set parent resource' do
          assert_equal @person, @controller.assigns[:person]
        end
      end
    end

    context 'load_parent with shallow option' do
      setup do
        @group = FactoryGirl.create(:group)
        @person = FactoryGirl.create(:person)
        NotesController.class_eval do
          load_parent :group, :person, shallow: true
        end
      end

      context 'when called without the parent id' do
        setup do
          @controller = NotesController.new
          @controller.action(:index)
        end

        should 'load no parent' do
          assert_nil @controller.assigns[:group]
          assert_nil @controller.assigns[:person]
        end

        should 'define child accessor' do
          assert_instance_of ActiveRecord::Relation, @controller.send(:notes)
        end
      end
    end

    context 'authorize parent' do
      setup do
        @group = FactoryGirl.create(:group)
        NotesController.class_eval do
          authorize_parent
        end
      end

      context 'when called with the parent id' do
        setup do
          @controller = NotesController.new(group_id: @group.id)
        end

        context 'parent not found' do
          should 'raise missing parameter exception' do
            assert_raise(ActionController::ParameterMissing) do
              @controller.action(:index)
            end
          end
        end

        context 'parent found and user not authorized' do
          setup do
            NotesController.class_eval do
              prepend_before_filter :get_parent

              private

              def get_parent
                @parent = FactoryGirl.create(:group, private: true)
              end

              def current_user
                FactoryGirl.create(:person).tap do |p|
                  p.define_singleton_method(:can_read?) { |r| false }
                end
              end
            end
          end

          should 'raise unauthorized exception' do
            assert_raise(Authority::SecurityViolation) do
              @controller.action(:index)
            end
          end
        end

        context 'parent found and user is authorized' do
          setup do
            NotesController.class_eval do
              prepend_before_filter :get_parent

              private

              def get_parent
                @parent = FactoryGirl.create(:group)
              end

              def current_user
                FactoryGirl.create(:person)
              end
            end
          end

          should 'raise unauthorized exception' do
            assert_nil @controller.action(:index)
          end
        end
      end
    end

    context 'load and authorize parent' do
      setup do
        @group = FactoryGirl.create(:group)
        NotesController.class_eval do
          load_and_authorize_parent :group
        end
      end

      should 'setup load and authorize options' do
        assert_equal([:group], NotesController.nested_resource_options[:load][:resources])
        assert_equal({shallow: nil}, NotesController.nested_resource_options[:load][:options])
        assert_equal({shallow: nil}, NotesController.nested_resource_options[:auth][:options])
      end

      should 'set before filters' do
        assert_equal [:load_parent, :authorize_parent], NotesController.filters
      end
    end

    context 'load resource' do
      setup do
        @note = FactoryGirl.create(:note)
        NotesController.class_eval do
          load_resource

          def note_params
            {title: 'test'}
          end
        end
      end

      context 'when called with an id' do
        setup do
          @controller = NotesController.new(id: @note.id)
          @controller.action(:show)
        end

        should 'find resource by id' do
          assert_equal @note, @controller.assigns[:note]
        end
      end

      context 'when create is called' do
        setup do
          @controller = NotesController.new
          @controller.action(:create)
          @note = @controller.assigns[:note]
        end

        should 'instantiate a new resource' do
          assert @note.new_record?
        end

        should 'set attributes on new resource' do
          assert_equal 'test', @note.title
        end
      end
    end

    context 'authorize resource' do
      setup do
        @note = FactoryGirl.create(:note)
        NotesController.class_eval do
          before_filter :get_note
          authorize_resource

          private

          def get_note
            @note = params[:id] ? Note.find(params[:id]) : Note.new
          end
        end
      end

      context 'user is not authorized' do
        setup do
          @controller = NotesController.new(id: @note.id)
          NotesController.class_eval do
            def current_user
              FactoryGirl.create(:person).tap do |p|
                p.define_singleton_method(:can_read?) { |r| false }
              end
            end
          end
        end

        should 'raise exception' do
          assert_raise(Authority::SecurityViolation) do
            @controller.action(:show)
          end
        end
      end

      context 'when create is called' do
        setup do
          @controller = NotesController.new
          NotesController.class_eval do
            def current_user
              FactoryGirl.create(:person).tap do |p|
                p.define_singleton_method(:can_create?) { |r| false }
              end
            end
          end
        end

        should 'instantiate a new resource' do
          assert_raise(Authority::SecurityViolation) do
            @controller.action(:create)
          end
        end
      end
    end
  end
end
