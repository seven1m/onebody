class StreamItemGrouper
  GROUPING_PERIOD = 1.hour

  class Grouper
    DEFAULT_EXPOSE_COUNT = 2

    def initialize(items, expose_count: DEFAULT_EXPOSE_COUNT)
      @items = items.dup
      @expose_count = expose_count
      expose
      group
    end

    attr_reader :grouped, :exposed

    def exposed_shared
      @exposed.select(&:shared)
    end

    private

    def expose
      @exposed = @items.pop(@expose_count)
      @exposed.unshift(@items.pop) while !enough_exposed? && @items.any?
      while (item = pop_unshared)
        @exposed.unshift(item)
      end
    end

    def group
      @grouped = @items
    end

    def enough_exposed?
      exposed_shared.size >= @expose_count
    end

    def pop_unshared
      index = @items.rindex { |i| !i.shared }
      @items.slice!(index) if index
    end
  end

  def initialize(base_item)
    raise 'base_item is nil' if base_item.nil?
    @base_item = base_item
  end

  def group
    destroy_existing_groups
    create_group
  end

  private

  def grouper
    @grouper ||= Grouper.new(items.to_a)
  end

  def items
    StreamItem \
      .order(:id)
      .where(streamable_type: @base_item.streamable_type)
      .where('created_at >= ?', @base_item.created_at - GROUPING_PERIOD)
  end

  def destroy_existing_groups
    items.map(&:stream_item_group).uniq.compact.each(&:destroy)
  end

  def create_group
    return if grouper.exposed_shared.none? || grouper.grouped.none?
    created_at = grouper.exposed_shared.first.created_at - 1.second
    StreamItem.create!(
      streamable_type: 'StreamItemGroup',
      context: {
        streamable_type: @base_item.streamable_type
      },
      items: grouper.grouped,
      created_at: created_at,
      shared: true,
      is_public: true
    )
  end
end
