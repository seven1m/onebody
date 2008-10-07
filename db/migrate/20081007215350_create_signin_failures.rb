class CreateSigninFailures < ActiveRecord::Migration
  def self.up
    create_table :signin_failures do |t|
      t.string :email, :ip
      t.datetime :created_at
    end
  end

  def self.down
    drop_table :signin_failures
  end
end
