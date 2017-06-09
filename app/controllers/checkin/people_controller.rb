class Checkin::PeopleController < ApplicationController
  def index
    select = 'families.id, families.barcode_id, people.family_id, people.id, people.first_name, people.last_name, people.suffix, people.classes, people.medical_notes, people.can_pick_up, people.cannot_pick_up, people.child, people.birthday'
    if params[:family_barcode_id]
      @people = Person.undeleted.joins(:family).where('(families.barcode_id = ? or families.alternate_barcode_id = ?)', params[:family_barcode_id], params[:family_barcode_id]).select(select)
    elsif params[:q]
      search = Search.new_from_params(family_name: params[:q])
      if (families = search.query(nil, 'family')).any?
        @people = Person.joins(:family).where("families.id in (#{families.map(&:id).join(',')}) and people.deleted = ?", false).select(select)
      else
        @people = []
      end
    else
      render text: 'missing param', status: 400
    end
    @people += Relationship.where("related_id in (?) and other_name like '%Check-in Person%'", @people.map(&:id)).map(&:person).uniq if @people.any?
    respond_to do |format|
      format.json do
        json = {
          'people' => @people.map do |person|
            person.attributes.merge(family_id: person.family_id,
                                    family_barcode_id: params[:family_barcode_id],
                                    attendance_records: person.attendance_today.each_with_object({}) do |record, records|
                                                          records[record.attended_at.to_s(:time)] = [record.group_id, record.group.name]
                                                        end)
          end,
          'meta' => {
            'groups_updated_at' => GroupTime.order('updated_at').last.updated_at
          }
        }.to_json
        render text: json
      end
    end
  end
end
