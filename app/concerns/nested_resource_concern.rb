require 'active_support/concern'

module NestedResourceConcern
  extend ActiveSupport::Concern

  METHOD_TO_ACTION_NAMES = {
    'show'    => 'read',
    'new'     => 'create',
    'create'  => 'create',
    'edit'    => 'update',
    'update'  => 'update',
    'destroy' => 'delete'
  }

  included do
    class_attribute :nested_resource_options
  end

  module ClassMethods

    # Macro sets a before filter to load the parent resource.
    # Pass in one symbol for each potential parent your nested under.
    #
    # For example, if you have routes:
    #
    #     resources :people do
    #       resources :notes
    #     end
    #
    #     resources :groups do
    #       resources :notes
    #     end
    #
    # ...you can call load_parent like so in your controller:
    #
    #     class NotesController < ApplicationController
    #       load_parent :person, :group
    #     end
    #
    # This will attempt to do the following for each resource, in order:
    #
    # 1. look for `params[:person_id]`
    # 2. if present, call `Person.find(params[:person_id])`
    # 3. set @person and @parent
    #
    # If we've exhausted our list of potential parent resources without
    # seeing the needed parameter (:person_id or :group_id), then a
    # ActionController::ParameterMissing is raised.
    #
    # Note: load_parent assumes you've only nested your route a single
    # layer deep, e.g. /parents/1/children/2
    # You're on your own if you want to load multiple nested
    # parents, e.g. /grandfathers/1/parents/2/children/3
    #
    # If you wish to also allow shallow routes (no parent), you can
    # set the `:shallow` option to `true`:
    #
    #     class NotesController < ApplicationController
    #       load_parent :person, :group, shallow: true
    #     end
    #
    # Additionally, a private method is defined with the same name as
    # the resource. The method looks basically like this:
    #
    #     class NotesController < ApplicationController
    #
    #       private
    #
    #       def notes
    #         if @parent
    #           @parent.notes.scoped
    #         else
    #           Note.scoped
    #         end
    #       end
    #     end
    #
    def load_parent(*names)
      options = names.extract_options!.dup
      self.nested_resource_options ||= {}
      self.nested_resource_options[:load] = {
        options: {shallow: options.delete(:shallow)},
        resources: names
      }
      before_filter :load_parent, options
      define_scope_method
    end

    # Macro sets a before filter to authorie the parent resource.
    # Assumes there is a `@parent` variable.
    #
    #     class NotesController < ApplicationController
    #       authorize_parent
    #     end
    #
    # If `@parent` is not found, or calling `authorize_resource(@parent)` fails,
    # an exception will be raised.
    #
    # If the parent resource is optional, and you only want to check authorization
    # if it is set, you can set the `:shallow` option to `true`:
    #
    #     class NotesController < ApplicationController
    #       authorize_parent shallow: true
    #     end
    #
    def authorize_parent(options={})
      self.nested_resource_options ||= {}
      self.nested_resource_options[:auth] = {
        options: {shallow: options.delete(:shallow)}
      }
      before_filter :authorize_parent, options
    end

    # A convenience method for calling both `load_parent` and `authorize_parent`
    def load_and_authorize_parent(*names)
      load_parent(*names)
      authorize_parent(names.extract_options!)
    end

    # Load the resource and set to an instance variable.
    #
    # For example:
    #
    #     class NotesController < ApplicationController
    #       load_resource
    #     end
    #
    # ...automatically finds the note for actions
    # `show`, `edit`, `update`, and `destroy`.
    #
    # For the `new` action, simply instantiates a
    # new resource. For `create`, instantiates and
    # sets attributes to `<resource>_params`.
    #
    def load_resource(options={})
      unless options[:only] or options[:except]
        options.reverse_merge!(only: [:show, :new, :create, :edit, :update, :destroy])
      end
      before_filter :load_resource, options
      define_scope_method
    end

    # Checks authorization on resource.
    def authorize_resource(options={})
      unless options[:only] or options[:except]
        options.reverse_merge!(only: [:show, :new, :create, :edit, :update, :destroy])
      end
      before_filter :authorize_resource, options
    end

    def load_and_authorize_resource(options={})
      load_resource(options)
      authorize_resource(options)
    end

    protected

    # Set the instance variable used to scope queries.
    # The variable is named after the controller, e.g. if your controller
    # is called `NotesController`, then the instance variable will be `@notes`.
    def define_scope_method
      define_method(controller_name) do
        if @parent
          @parent.send(controller_name).scoped
        else
          controller_name.classify.constantize.scoped
        end
      end
      private(controller_name)
    end
  end

  protected

  # Loop over each parent resource, and try to find a matching parameter.
  # Then lookup the resource using the supplied id.
  def load_parent
    keys = self.class.nested_resource_options[:load][:resources]
    parent = keys.detect do |key|
      if id = params["#{key}_id".to_sym]
        @parent = key.to_s.classify.constantize.find(id)
        instance_variable_set "@#{key}", @parent
      end
    end
    verify_shallow_route! unless @parent
  end

  def load_resource
    scope = send(controller_name)
    if ['new', 'create'].include?(params[:action].to_s)
      resource = scope.new
      if 'create' == params[:action].to_s
        resource.attributes = send("#{controller_name.singularize}_params")
      end
    elsif params[:id]
      resource = scope.find(params[:id])
    else
      resource = nil
    end
    instance_variable_set("@#{resource_name}", resource)
  end

  # Verify the current user is authorized to view the parent resource.
  # Assumes that `load_parent` has already been run and that `@parent` is set.
  # If `@parent` is empty and the `shallow` option is enabled, don't
  # perform any authorization check.
  def authorize_parent
    if not @parent and not self.class.nested_resource_options[:auth][:options][:shallow]
      raise ActionController::ParameterMissing.new('parent resource not found')
    end
    if @parent
      authorize_resource(@parent, :read)
    end
  end

  # Default authorization method compatible with the "Authorize" gem
  # Override this method if you wish to use another means for authorization.
  def authorize_resource(resource=nil, action=nil)
    resource ||= instance_variable_get("@#{controller_name.singularize}")
    action ||= METHOD_TO_ACTION_NAMES[params[:action].to_s]
    raise ArgumentError unless resource and action
    unless current_user.send("can_#{action}?", resource)
      raise Authority::SecurityViolation.new(current_user, action, resource)
    end
  end

  # Verify this shallow route is allowed, otherwise raise an exception.
  def verify_shallow_route!
    return if self.class.nested_resource_options[:load][:options][:shallow]
    expected = self.class.nested_resource_options[:load][:resources].map { |n| ":#{n}_id" }
    raise ActionController::ParameterMissing.new(
      "must supply one of #{expected.join(', ')}"
    )
  end

  def resource_name
    controller_name.singularize
  end
end
