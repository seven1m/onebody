require 'ostruct'

class FamilySearch < Search
  attr_accessor :name,
                :barcode_id,
                :select_family,
                :show_hidden

  def initialize(params = {})
    params[:name] = params.delete(:family_name)
    params[:barcode_id] = params.delete(:name) if params[:name] =~ /^\d+$/
    params[:barcode_id] ||= params.delete(:family_barcode_id)
    super(params)
  end

  def build_scope
    @scope = Family.includes(:people)
  end

  private

  def execute
    return if @executed
    filter_not_deleted
    order_by_name
    filter_name
    filter_visible
    filter_barcode_id
    @executed = true
  end

  def filter_not_deleted
    where(families: { deleted: false })
  end

  def order_by_name
    order('LOWER(families.last_name), LOWER(families.name)')
  end

  def filter_visible
    return if show_hidden_profiles?
    where(families: { visible: true })
  end

  def filter_name
    return unless name
    where(
      "(families.name #{like} :name)
       or (families.name #{like} :name_and)
      ",
      name:     like_match(name),
      name_and: like_match(name.sub(/ and /, ' & '))
    )
  end

  def filter_barcode_id
    where('families.barcode_id = :id or families.alternate_barcode_id = :id', id: barcode_id) if barcode_id
  end

  def show_hidden_profiles?
    ((show_hidden || select_family) && Person.logged_in.admin?(:view_hidden_profiles))
  end
end
