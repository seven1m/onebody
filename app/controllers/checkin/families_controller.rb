class Checkin::FamiliesController < ApplicationController
  def show
    @family = Family.undeleted.find(params[:id])
    @family_people = @family.people.undeleted.order(:position)
    @attendance_records = AttendanceRecord.find_for_people_and_date(@family_people.map(&:id), Date.current)
                                          .group_by(&:person_id)
  end

  def new
    family_form = FamilyFormPresenter.new
    @family = family_form.family
    @people = family_form.build_people
  end

  def create
    family_form = FamilyFormPresenter.new(params)
    family_form.create
    @family = family_form.family
    @people = family_form.people
    render action: 'new' if @family.errors.any?
  end

  def update
    @family = Family.undeleted.find(params[:id])
    @family.barcode_id = params[:family][:barcode_id]
    @family.alternate_barcode_id = params[:family][:alternate_barcode_id]
    @success = @family.save
    respond_to do |format|
      format.js
    end
  end

  private

  def build_family_people
    @people = @family.people.to_a
    adults = []
    adults << @people.shift until adults.length >= 2 || @people.first.nil? || @people.first.child?
    adults << @family.people.adults.build until adults.length >= 2
    @people.unshift(*adults)
    @people << @family.people.children.build until @people.length >= 25
  end
end
