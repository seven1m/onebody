class MakeCommentsPolymorphic < ActiveRecord::Migration[4.2]
  def up
    change_table :comments do |t|
      t.references :commentable, polymorphic: true
    end

    Comment.reset_column_information

    print 'Updating comments'
    Site.each do
      Comment.all.each do |comment|
        if comment.verse_id
          comment.commentable_type = 'Verse'
          comment.commentable_id = comment.verse_id
        elsif comment.picture_id
          comment.commentable_type = 'Picture'
          comment.commentable_id = comment.picture_id
        end
        comment.save(validate: false)
        print '.'
      end
    end
    puts
  end

  def down
    change_table :comments do |t|
      t.remove :commentable_id
      t.remove :commentable_type
    end
  end
end
