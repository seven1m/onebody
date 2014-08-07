class Administration::DonationsController < ApplicationController

  before_filter :only_admins

  def index
  end

  def new
    @donation = Donation.new
  end

end