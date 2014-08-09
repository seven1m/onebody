require 'chronic'

class Administration::DonationsController < ApplicationController

  before_filter :only_admins

  def index
    @donations = Donation.all
    @date = Chronic.parse('last sunday')
  end

  def new
    @donation = Donation.new
    @date = Chronic.parse('last sunday')
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