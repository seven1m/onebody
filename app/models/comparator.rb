class Comparator
  def initialize(model, attributes)
    @model = model
    @attributes = HashWithIndifferentAccess.new(attributes.to_h)
    compare
  end

  attr_reader :changes
  def changed?
    @changed
  end

  private

  def compare
    @model.attributes = @attributes              # temporarily set the attributes on the model
    @changes = @model.changes                    # get all model changes
    @changed = @model.changed?                   # did model change?
    @model.reload                                # reset the model
    @changes.select! { |k| @attributes.key?(k) } # return only keys that were in original hash
  end
end
