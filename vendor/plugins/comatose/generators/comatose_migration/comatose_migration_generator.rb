class ComatoseMigrationGenerator < Rails::Generator::Base


  def initialize(runtime_args, runtime_options = {})
    @mode = :new
    if runtime_args.include? '--upgrade' or runtime_args.include? '-u'
      @mode = :upgrade
      @upgrade_from = nil
      runtime_args.delete '--upgrade'
      runtime_args.delete '-u'
      
      runtime_args.each do |arg|
        if arg.starts_with? '--from'
          @upgrade_from = arg[7..-1] 
        elsif arg.starts_with? '-f'
          @upgrade_from = arg[3..-1] 
        end
        runtime_args.delete arg
      end
            
      if  @upgrade_from.nil? or  @upgrade_from.empty?
        puts ""
        puts "Please specify which version of Comatose you're upgrading from:"
        puts ""
        puts "  ./script/generate comatose_migration --upgrade --from=0.3"
        puts ""
        puts "Upgrade canceled"
        exit(0)
      end
      
      puts "Upgrading from version #{ @upgrade_from }"
    end
    super
  end

  def manifest
    record do |m|
      case @mode
      when :new
        m.migration_template 'migration.rb', 'db/migrate', :migration_file_name=>'add_comatose_support', :assigns=>{:class_name=>'AddComatoseSupport'}
        
      when :upgrade
        from = @upgrade_from
        if from == '0.3'
          m.migration_template 'v4_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v04', :assigns=>{:class_name=>'UpgradeToComatoseV04'}
          m.migration_template 'v6_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v06', :assigns=>{:class_name=>'UpgradeToComatoseV06'}
          m.migration_template 'v7_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v07', :assigns=>{:class_name=>'UpgradeToComatoseV07'}
        end
        if from == '0.4' or from == '0.5'
          m.migration_template 'v6_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v06', :assigns=>{:class_name=>'UpgradeToComatoseV06'}
          m.migration_template 'v7_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v07', :assigns=>{:class_name=>'UpgradeToComatoseV07'}
        end
        if from == '0.6'
          m.migration_template 'v7_upgrade.rb', 'db/migrate', :migration_file_name=>'upgrade_to_comatose_v07', :assigns=>{:class_name=>'UpgradeToComatoseV07'}
        end
      end
    end
  end
end
