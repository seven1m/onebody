module Administration::DeletedPeopleHelper

  def sortable_column_heading(label, sort)
    new_sort = (sort.split(',') + params[:sort].to_s.split(',')).uniq.join(',')
    link_to label, administration_deleted_people_path(:page => params[:page], :sort => new_sort)
  end

end
