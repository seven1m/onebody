class UseBcryptForPasswords < ActiveRecord::Migration
  def up
    change_table :people do |t|
      t.string :password_hash, :password_salt
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new('cannot migrate back from bcrypted passwords')
  end
end
