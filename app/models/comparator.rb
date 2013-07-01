class Comparator

  def initialize(model, attributes)
    @model = model
    @attributes = HashWithIndifferentAccess.new(attributes)
  end

  def changes
    @model.attributes = @attributes            # temporarily set the attributes on the model
    changes = @model.changes                   # get all model changes
    @model.reload                              # reset the model
    changes.select { |k| @attributes.key?(k) } # return only keys that were in original hash
  end

end
