class Giving::TransactionsController < ApplicationController
  def new
    @transaction = DonationTransaction.new
  end

  def create
    begin
      transaction_id = params[:donation_transaction][:transaction_id]
      amount = params[:donation_transaction][:amount]
      transaction_email = params[:donation_transaction][:transaction_email]

      # Parse amount to get it to cents
      amount = (amount.to_f * 100).to_i

      customer = Stripe::Customer.create(
        email: transaction_email,
        source: transaction_id
      )

      charge = Stripe::Charge.create(
        customer: customer.id,
        amount: amount,
        description: "Donation on #{Setting.get(:name, :site)}",
        currency: 'usd'
      )

    rescue Stripe::CardError => e
    end

    redirect_to giving_path
  end
end
