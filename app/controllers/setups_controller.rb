class SetupsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :check_setup_requirements

  def show
    redirect_to new_setup_path
  end

  def new
    @person = Person.new
  end

  def create
    @setup = Setup.new(params.permit!)
    if @setup.execute!
      flash[:notice] = t('setup.complete')
      redirect_to new_session_path(from: '/stream')
    else
      @person = @setup.person
      render action: 'new'
    end
  end

  private

    def check_setup_requirements
      if Person.count > 0
        render text: t('not_authorized'), layout: true
        return false
      end
    end

end
