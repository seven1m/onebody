module Administration::SyncsHelper

  def syncable_path(sync_item)
    if sync_item.syncable_id
      case sync_item.syncable_type
        when 'Person'
          person_path(sync_item.syncable_id)
        when 'Family'
          family_path(sync_item.syncable_id)
        when 'Group'
          group_path(sync_item.syncable_id)
        else
          raise 'Error - unknown syncable_type in helper syncable_path()'
      end
    else
      nil
    end
  end

end
