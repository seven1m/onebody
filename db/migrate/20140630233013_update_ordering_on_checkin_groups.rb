class UpdateOrderingOnCheckinGroups < ActiveRecord::Migration
  def change
    Site.each do
      CheckinTime.all.each do |time|
        time.group_times.all.each_with_index do |group, index|
          group.ordering = index + 1
          group.save(validate: false)
        end
      end
    end
  end
end
