class FamilyFormPresenter

  attr_reader :params, :people

  def initialize(params={})
    @params = params
  end

  def create
    @family = Family.new(family_params)
    @family.people.each { |p| p.set_child; p.status = :pending }
    @family.name = @family.suggested_name
    @family.last_name = @family.suggested_last_name
    validate_params
    if not @family.errors.any? and @family.save
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
    attrs.reject! { |i, p| p[:first_name].blank? }
    (2..25).each do |i|
      attrs[i.to_s][:child] = true if attrs[i.to_s] and attrs[i.to_s][:birthday].blank?
    end
    params[:family].permit(:barcode_id,
                           people_attributes: [:first_name, :last_name, :birthday, :medical_notes, :child])
  end

  def validate_params
    if not params[:family][:people_attributes].all? { |i, p| ['0', '1'].include?(i) or Date.parse_in_locale(p[:birthday]) rescue nil }
      @family.errors.add :base, I18n.t('checkin.family.error.no_birthdays')
    elsif @family.people.empty?
      @family.errors.add :base, I18n.t('checkin.family.error.no_people')
    elsif @family.people.none?(&:adult?)
      @family.errors.add :base, I18n.t('checkin.family.error.no_parents')
    elsif params[:family][:barcode_id].blank?
      @family.errors.add :base, I18n.t('checkin.family.error.no_barcode')
    end
  end

  def build_adults
    adults = shift_adults_from_people
    adults << @family.people.adults.build until adults.length >= 2
    @people.unshift(*adults)
  end

  def shift_adults_from_people
    [].tap do |adults|
      until adults.length >= 2 or @people.first.nil? or @people.first.child?
        adults << @people.shift
      end
    end
  end

  def build_children
    @people << @family.people.children.build until @people.length >= 25
  end
end
