class FamilyFormPresenter
  attr_reader :params, :people

  def initialize(params = {})
    @params = params.deep_dup
    @params[:family] ||= {}
    @params[:family][:people_attributes] ||= {}
  end

  def create
    @family = Family.new(family_params)
    @family.people.each { |p| p.set_child; p.status = :pending }
    @family.name = @family.suggested_name
    @family.last_name = @family.suggested_last_name
    validate_params
    if @family.errors.none? && @family.save
      true
    else
      build_people
      false
    end
  end

  def family
    @family ||= Family.new
  end

  def build_people
    return @people if @people
    @people = @family.people.to_a
    build_adults
    build_children
    @people
  end

  private

  def family_params
    attrs = params[:family][:people_attributes]
    attrs['0'][:child] = false if attrs['0']
    attrs['1'][:child] = false if attrs['1']
    attrs.reject! { |_i, p| p[:first_name].blank? }
    (2..25).each do |i|
      attrs[i.to_s][:child] = true if attrs[i.to_s] && attrs[i.to_s][:birthday].blank?
    end
    params[:family].permit(:barcode_id,
                           people_attributes: %i(first_name last_name birthday medical_notes child))
  end

  def validate_params
    people_attrs = params[:family][:people_attributes].to_unsafe_h # just used for verifying attributes are present
    if !people_attrs.all? { |i, p| %w(0 1).include?(i) || date_from_param(p[:birthday]) }
      @family.errors.add :base, I18n.t('checkin.family.error.no_birthdays')
    elsif @family.people.empty?
      @family.errors.add :base, I18n.t('checkin.family.error.no_people')
    elsif @family.people.none?(&:adult?)
      @family.errors.add :base, I18n.t('checkin.family.error.no_parents')
    elsif params[:family][:barcode_id].blank?
      @family.errors.add :base, I18n.t('checkin.family.error.no_barcode')
    end
  end

  def date_from_param(d)
    Date.parse_in_locale(d)
  rescue
    nil
  end

  def build_adults
    adults = shift_adults_from_people
    adults << @family.people.adults.build until adults.length >= 2
    @people.unshift(*adults)
  end

  def shift_adults_from_people
    [].tap do |adults|
      until adults.length >= 2 || @people.first.nil? || @people.first.child?
        adults << @people.shift
      end
    end
  end

  def build_children
    @people << @family.people.children.build until @people.length >= 25
  end
end
