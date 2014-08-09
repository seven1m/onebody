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

  def summary
    @date = Chronic.parse('last sunday')
    @donations = Donation.all
    @summary = Hash[DONATION_TYPE.collect {|t| [t, sum(t)]}]
  end

  private

  def donation_params
    params.require(:donation).permit(:date, :person_id, :family_id, :donation_type, :name, :amount_cents, :amount_currency)
  end

  def sum(t)
    total = 0
    @donations.each do |donation|
      if donation.donation_type == t
        total += donation.amount_cents
      end
    end
    return total
  end
end