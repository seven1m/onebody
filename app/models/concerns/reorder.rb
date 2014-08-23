require 'active_support/concern'

module Concerns
  module Reorder

    def reorder_entry(entry, direction, full_stop=false)
      all = entries.to_a
      index = all.index(entry)
      case direction
      when 'up'
        index = 1 if full_stop
        all.delete(entry)
        all.insert([index - 1, 0].max, entry)
      when 'down'
        index = all.length - 1 if full_stop
        all.delete(entry)
        all.insert([index + 1, all.length].min, entry)
      end
      all.each_with_index { |g, i| g.update_attribute(:sequence, i + 1) }
      reload
    end
  end
end
