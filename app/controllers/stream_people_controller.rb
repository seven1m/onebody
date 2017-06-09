class StreamPeopleController < ApplicationController
  def index
    @people = @logged_in \
              .sharing_with_people \
              .minimal.select(:family_id) \
              .order(:first_name, :last_name) \
              .page(params[:page])
  end
end
