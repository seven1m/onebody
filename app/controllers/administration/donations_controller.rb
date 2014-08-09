class Administration::DonationsController < ApplicationController

  before_filter :only_admins

  def index
    @donations = Donation.all
  end

  def new
    @donation = Donation.new
  end

  def create
    @donation = Donation.new(donation_params)
    @donation.save
  end

  private

  def donation_params
    params.require(:donation).permit(:date, :person_id, :family_id, :donation_type, :name, :amount_cents, :amount_currency)
  end
end