class StreamItem < ActiveRecord::Base
  belongs_to :person
  belongs_to :site
  belongs_to :streamable, :polymorphic => true
end
