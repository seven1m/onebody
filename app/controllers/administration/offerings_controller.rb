require 'chronic'

class Administration::OfferingsController < ApplicationController

  before_filter :only_admins

  def index
    @offerings = Offering.all
    @date = Chronic.parse('last sunday')
  end

  def new
    @offering = Offering.new
    @date = Chronic.parse('last sunday')
  end

  def create
    @offering = Offering.new(offering_params)
    @offering.save
  end

  def summary
    @date = Chronic.parse('last sunday')
    @offerings = Offering.all
    @summary = Hash[OFFERING_TYPE.collect {|t| [t, sum(t)]}]
  end

  private

  def offering_params
    params.require(:offering).permit(:date, :person_id, :family_id, :offering_type, :name, :amount_cents, :amount_currency)
  end

  def sum(t)
    total = 0
    @offerings.each do |offering|
      if offering.offering_type == t
        total += offering.amount_cents
      end
    end
    return total
  end
end