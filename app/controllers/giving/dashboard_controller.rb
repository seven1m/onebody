class Giving::DashboardController < ApplicationController
  def show
    @transactions = DonationTransaction.where(user_id: @logged_in.id)
  end
end
