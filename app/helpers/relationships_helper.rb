module RelationshipsHelper
  def relationships_for_select
    options_for_select(relationship_labels)
  end

  def relationship_labels
    I18n.t('relationships.names').dup.tap do |hash|
      hash[:other] = hash.delete(:other_name) # OneSky doesn't like the key 'other'
    end.invert.sort
  end
end
