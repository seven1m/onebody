require 'active_support/concern'

module Concerns
  module Reorder
    def reorder_entry(entry, direction, full_stop = false)
      all = entries.to_a
      index = all.index(entry)
      case direction
      when 'up'
        index = 1 if full_stop
        all.delete(entry)
        new_index = [index - 1, 0].max
        all.insert(new_index, entry)
      when 'down'
        index = all.length - 1 if full_stop
        all.delete(entry)
        new_index = [index + 1, all.length].min
        all.insert(new_index, entry)
      end
      resequence(all)
    end

    def resequence(all = entries)
      all.each_with_index { |g, i| g.update_attribute(:sequence, i + 1) }
      reload
    end

    def update_sequence(entry)
      if entry.sequence.nil?
        max = entries.map { |e| e.sequence.to_i }.max
        entry.update_attribute(:sequence, (max || 0) + 1)
      end
    end
  end
end
