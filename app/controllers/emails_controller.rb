class EmailsController < ApplicationController

  skip_before_filter :authenticate_user

  def create
    Notifier.receive(params['body-mime'])
    render nothing: true
  end

end
