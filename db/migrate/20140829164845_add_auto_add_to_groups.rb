class AddAutoAddToGroups < ActiveRecord::Migration[4.2]
  def up
    change_table :groups do |t|
      t.string :membership_mode, limit: 10, default: 'manual'
    end

    Group.reset_column_information

    Person.class_eval do
      # 'position' was 'sequence' prior to RenamePersonSequenceToPosition
      def position
        sequence
      end
    end

    print 'Updating groups'
    Site.each do
      Group.all.each do |group|
        if group.linked?
          group.membership_mode = 'link_code'
        elsif group.parents_of.present?
          group.membership_mode = 'parents_of'
        else
          group.membership_mode = 'manual'
        end
        group.dont_update_memberships
        group.save(validate: false)
        print '.'
      end
    end
    puts

    Person.class_eval do
      remove_method :position
    end
  end

  def down
    change_table :groups do |t|
      t.remove :membership_mode
    end
  end
end
