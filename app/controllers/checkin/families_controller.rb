class Checkin::FamiliesController < ApplicationController

  def show
    @family = Family.find_by_id_and_deleted(params[:id], false)
    raise ActiveRecord::RecordNotFound unless @family
    @family_people = @family.people.undeleted.order(:sequence)
    @attendance_records = AttendanceRecord.find_for_people_and_date(@family_people.map(&:id), Date.today).group_by(&:person_id)
    respond_to do |format|
      format.js
    end
  end

  def new
    @family = Family.new
    build_family_people
  end

  def create
    parents = ['0', '1'].map { |i| params[:family][:people_attributes][i] }
    parents.each { |p| p[:child] = false }
    params[:family][:people_attributes].reject! { |i, p| p[:first_name].blank? }
    @family = Family.new(family_params)
    if not params[:family][:people_attributes].all? { |i, p| Date.parse_in_locale(p[:birthday]) rescue nil }
      @family.errors.add :base, t('checkin.family.error.no_birthdays')
      build_family_people
      render action: 'new'
    elsif @family.people.empty?
      @family.errors.add :base, t('checkin.family.error.no_people')
      build_family_people
      render action: 'new'
    elsif @family.people.none?(&:adult?)
      @family.errors.add :base, t('checkin.family.error.no_parents')
      build_family_people
      render action: 'new'
    elsif params[:family][:barcode_id].blank?
      @family.errors.add :base, t('checkin.family.error.no_barcode')
      build_family_people
      render action: 'new'
    else
      parents.reject! { |p| p['first_name'].blank? }
      if parents.length == 2
        if parents[0]['last_name'] == parents[1]['last_name']
          @family.name = "#{parents[0]['first_name']} & #{parents[1]['first_name']} #{parents[0]['last_name']}"
        else
          @family.name = "#{parents[0]['first_name']} #{parents[0]['last_name']} & #{parents[1]['first_name']} #{parents[1]['last_name']}"
        end
      else
        @family.name = "#{parents[0]['first_name']} #{parents[0]['last_name']}"
      end
      @family.last_name = parents[0]['last_name']
      unless @family.save
        build_family_people
        render action: 'new'
      end
    end
  end

  def update
    @family = Family.find(params[:id])
    @family.barcode_id = params[:family][:barcode_id]
    @family.alternate_barcode_id = params[:family][:alternate_barcode_id]
    @success = @family.save
    respond_to do |format|
      format.js
    end
  end

  private

  def family_params
    params[:family].permit(:barcode_id, people_attributes: [:first_name, :last_name, :birthday, :medical_notes])
  end

  def build_family_people
    (25 - @family.people.length).times { @family.people.build }
  end
end
