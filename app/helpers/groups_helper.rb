module GroupsHelper
  include StreamsHelper

  def group_box_class(group)
    if group.private?
      'box-danger'
    elsif group.hidden?
      'box-warning'
    else
      'box-success'
    end
  end
end
