class Sync < ActiveRecord::Base
  belongs_to :site
  scope_by_site_id

  attr_accessible :complete, :success_count, :error_count, :started_at, :finished_at

  belongs_to :person
  has_many :sync_items, :dependent => :delete_all
  has_many :people,   :through => :sync_items, :source => :syncable, :source_type => 'Person'
  has_many :families, :through => :sync_items, :source => :syncable, :source_type => 'Family'
  has_many :groups,   :through => :sync_items, :source => :syncable, :source_type => 'Group'

  def total_count
    success_count.to_i + error_count.to_i
  end

  def success_rate
    if !complete?
      nil
    elsif total_count > 0
      success_count.to_i / total_count.to_f * 100.0
    else
      100.0
    end
  end

  def count_items
    {
      :create => sync_items.count('id', :conditions => {:operation => 'create'}),
      :update => sync_items.count('id', :conditions => {:operation => 'update'}),
      :error  => sync_items.count('id', :conditions => "status in ('error', 'saved with error')"),
    }.reject { |k, v| v == 0 }
  end

  # meant to be started as a background job
  # syncs data uploaded by PowerChurch
  def do_pc_sync(guid, force=false, preserve_files=false)
    return if self.complete? and !force
    sync_items.destroy_all
    self.success_count = 0
    self.error_count = 0
    guid = guid.scan(/[a-z0-9]/).join
    sync_path = File.join(Rails.root, 'tmp', 'pc_sync')
    guid_path = File.join(sync_path, guid)
    FileUtils.rm_rf(guid_path) if force
    FileUtils.mkdir_p(guid_path)
    Dir[File.join(sync_path, '*.zip')].each do |path|
      filename = File.split(path).last
      if filename =~ /^#{guid}-/
        Zip::ZipFile.foreach(path) do |entry|
          if %w(ob1_families ob2_people ob3_group ob4_memberships ob5_parentsof).include?(entry.to_s)
            entry_filename = File.join(guid_path, entry.to_s)
            entry.extract(entry_filename)
          end
        end
        FileUtils.rm(path)
      end
    end
    if File.exist?(filename = File.join(guid_path, 'ob1_families'))
      Rails.logger.info('Syncing Families...')
      do_pc_sync_families(filename)
    end
    if File.exist?(filename = File.join(guid_path, 'ob2_people'))
      Rails.logger.info('Syncing People...')
      do_pc_sync_people(filename)
    end
    if File.exist?(filename = File.join(guid_path, 'ob3_group'))
      Rails.logger.info('Syncing Groups...')
      do_pc_sync_groups(filename)
    end
    if File.exist?(filename = File.join(guid_path, 'ob4_memberships'))
      Rails.logger.info('Syncing Memberships...')
      do_pc_sync_memberships(filename)
    end
    if File.exist?(filename = File.join(guid_path, 'ob5_parentsof'))
      Rails.logger.info('Syncing Parents of...')
      do_pc_sync_parentsof(filename)
    end
    Rails.logger.info('Finished: ' + Time.now.to_s)
    self.finished_at = Time.now
    self.complete = true
    self.save!
    FileUtils.rm_rf(guid_path) unless preserve_files
  end

  def do_pc_sync_families(filename)
    family_ids = []
    begin
      families = Hash.from_xml(File.read(filename))['onebody']['families']
    rescue
      Rails.logger.info('No Families to sync')
    else  
      families.each do |family_hash|
        family_ids << legacy_id = family_hash['legacy_id'].to_i
        operation = nil
        if family = Family.find_by_legacy_id(legacy_id)
          family.deleted = false
          family.save
          operation = 'update'
        else
          operation = 'create'
        end
        status = Family.update_batch([family_hash]).first
        error = status[:error] && status[:error].split('; ')
        sync_items.create(
          :syncable_type  => 'Family',
          :syncable_id    => status[:id],
          :name           => status[:name],
          :legacy_id      => legacy_id,
          :operation      => operation,
          :status         => status[:status],
          :error_messages => error
        )
        if status[:status] == 'not saved'
          self.increment(:error_count)
        else
          self.increment(:success_count)
        end
      end
      Family.update_all(['deleted = ?', true], ['site_id = ? and deleted = ? and id != ? and legacy_id not in (?)', Site.current.id, false, self.person.family_id, family_ids])
    end
    Rails.logger.info('Syncing Families...done')
  end

  def do_pc_sync_people(filename)
    people_ids = []
    begin
      people = Hash.from_xml(File.read(filename))['onebody']['people']
    rescue
      Rails.logger.info('No People to sync')
    else
      people.each do |person_hash|
        people_ids << legacy_id = person_hash['legacy_id'].to_i
        operation = nil
        if person = Person.find_by_legacy_id(legacy_id)
          person.deleted = false
          person.save
          operation = 'update'
        else
          operation = 'create'
        end
        status = Person.update_batch([person_hash]).first
        error = status[:error] && status[:error].split('; ')
        sync_items.create(
          :syncable_type  => 'Person',
          :syncable_id    => status[:id],
          :name           => status[:name],
          :legacy_id      => legacy_id,
          :operation      => operation,
          :status         => status[:status],
          :error_messages => error
        )
        if status[:status] == 'not saved'
          self.increment(:error_count)
        else
          self.increment(:success_count)
        end
      end
      Person.update_all(['deleted = ?', true], ['site_id = ? and deleted = ? and id != ? and legacy_id not in (?)', Site.current.id, false, self.person.id, people_ids])
    end
    Rails.logger.info('Syncing People...done')
  end

  def do_pc_sync_groups(filename)
    group_ids = []
    begin 
      groups = Hash.from_xml(File.read(filename))['onebody']['groups']
    rescue
      Rails.logger.info('No Groups to sync')
    else  
      groups.each do |group_hash|
        group_ids << legacy_id = group_hash['legacy_id'].to_i
        operation = nil
        if group = Group.find_by_legacy_id(legacy_id)
          operation = 'update'
        else
          group = Group.new
          operation = 'create'
        end
        group.name      = group_hash['name']
        group.private   = group_hash['private']
        group.approved  = group_hash['approved']
        group.legacy_id = group_hash['legacy_id']
        group.category  = group_hash['category']
        status = group.save ? 'saved' : 'not saved'
        sync_items.create(
          :syncable_type  => 'Group',
          :syncable_id    => group.id,
          :name           => group.name,
          :legacy_id      => legacy_id,
          :operation      => operation,
          :status         => status,
          :error_messages => status == 'not saved' ? group.errors.full_messages : nil
        )
        if status == 'not saved'
          self.increment(:error_count)
        else
          self.increment(:success_count)
        end
      end
    end
    Group.delete_all(['site_id = ? and legacy_id is not null and legacy_id not in (?)', Site.current.id, group_ids])
    Rails.logger.info('Syncing Groups...done')
  end

  def do_pc_sync_memberships(filename)
    begin
      memberships = Hash.from_xml(File.read(filename))['onebody']['memberships']
    rescue
      Rails.logger.info('No Memberships to sync')
    else
      by_group_id = memberships.inject({}) do |hash, membership|
        hash[membership['group_id'].to_i] ||= []
        hash[membership['group_id'].to_i] << membership['person_id'].to_i
        hash
      end
      by_group_id.each do |group_id, people_ids|
        if group = Group.find_by_legacy_id(group_id)
          people = Person.all(:conditions => ['legacy_id in (?)', people_ids])
          people.each do |person|
            unless person.member_of?(group)
              group.memberships.create!(:person => person)
            end
          end
          Membership.delete_all(['site_id = ? and group_id = ? and person_id not in (?)', Site.current.id, group.id, people.map { |p| p.id }])
        end
      end
    end
    Rails.logger.info('Syncing Memberships...done')
  end

  def do_pc_sync_parentsof(filename)
    begin
      group_ids = Hash.from_xml(File.read(filename))['onebody']['parentsof'].map { |g| g['legacy_id'] }
    rescue
      Rails.logger.info('No Parents-of Groups to sync')
    else
      group_ids.each do |group_id|
        if group = Group.find_by_legacy_id(group_id)
          if pgroup = Group.find_by_parents_of(group_id)
            pgroup.update_memberships
          else
            pgroup = Group.new
            pgroup.name = "Parents of #{group.name}"
            pgroup.category = 'Parent Group'
            pgroup.approved = true
            pgroup.private = true
            pgroup.parents_of = group.id
            pgroup.save!
          end
        end
      end
    end
  end

end
