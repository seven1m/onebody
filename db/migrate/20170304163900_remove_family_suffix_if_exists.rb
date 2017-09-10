class RemoveFamilySuffixIfExists < ActiveRecord::Migration[4.2]
  def up
    # this was inadvertently added some time back and never used
    # some databases, through some weird migration worm hole, never got this column
    Family.reset_column_information
    remove_column(:families, :suffix) if Family.columns.map(&:name).include?('suffix')
  end

  def down
  end
end
