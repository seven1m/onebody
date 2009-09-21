module Administration::AttendanceHelper
  
  def sortable_column_heading(label, sort)
    new_sort = (sort.split(',') + params[:sort].to_s.split(',')).uniq.join(',')
    link_to label, administration_attendance_index_path(:group_id => params[:group_id], :page => params[:page], :sort => new_sort)
  end
  
end
