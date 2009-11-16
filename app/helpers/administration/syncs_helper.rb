module Administration::SyncsHelper
  
  def sortable_column_heading(label, sort)
    new_sort = (sort.split(',') + params[:sort].to_s.split(',')).uniq.join(',')
    link_to label, administration_sync_path(@sync, :page => params[:page], :sort => new_sort)
  end
  
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
