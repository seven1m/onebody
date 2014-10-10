class WeeklyAttendanceReport < Dossier::Report
  include ReportsHelper

  def sql
    "SELECT `groups`.`name`, attended_at, first_name, last_name, 'Yes'
    FROM `groups` INNER JOIN `attendance_records`
    ON `attendance_records`.`group_id` = `groups`.`id`
    AND `attendance_records`.`site_id` = 1.
      WHERE (attended_at >= :fromdate and attended_at <= :thrudate)".tap do |sql|
      sql << " AND `attendance_records`.`group_id` = :sel_group " if options[:sel_group].present?
      sql << "UNION select
              groups.name,
              null,
              people.first_name,
              people.last_name,
              'No'
              from memberships,
                   people,
                   groups
                   where memberships.person_id = people.id
                         and memberships.group_id = groups.id
                         and memberships.created_at <= :fromdate
                         and exists (select 'x'
                               from attendance_records
                               where attendance_records.group_id = memberships.group_id
                               and   attendance_records.attended_at >= :fromdate
                               and   attendance_records.attended_at <= :thrudate)
                               and (concat(memberships.group_id, memberships.person_id)
                               not in (select concat(attendance_records.group_id, attendance_records.person_id)
                                     from attendance_records,
                                          people
                                          where attendance_records.person_id = people.id " if options[:data_filter] == '2'
                                                sql << "and attendance_records.group_id = :sel_group " if options[:sel_group].present? and options[:data_filter] == '2'
                                                sql << "and   attendance_records.attended_at >= :fromdate
                                                and   attendance_records.attended_at <= :thrudate ))" if options[:data_filter] == '2'

    end # tap.do
  end

  def fromdate
     format_dateparam(options[:fromdate], (Date.current - 1.week))
  end

  def thrudate
     format_dateparam(options[:thrudate])
  end

  def format_attended_at(value)
      format_date(value)
  end

  def sel_group
     options[:sel_group]
  end

  def data_filter
    options[:data_filter]
  end

end
