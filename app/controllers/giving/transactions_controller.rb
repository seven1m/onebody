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

      DonationTransaction.create(
        user_id: @logged_in.id,
        amount: amount,
        transaction_id: charge.id,
        transaction_email: transaction_email
      )

      flash[:notice] = t('giving.flash.success')
      redirect_to giving_path
      
    rescue Stripe::CardError => e
      flash[:error] = t('giving.flash.card_error')
    rescue Stripe::RateLimitError => e
      flash[:error] = t('giving.flash.generic_error')
      logger.info "Stripe rate limit error"
    rescue Stripe::InvalidRequestError => e
      flash[:error] = t('giving.flash.system_error', admin_email: Setting.get(:contact, :bug_notification_email))
      log_error "Invalid Request Error", e
    rescue Stripe::AuthenticationError => e
      flash[:error] = t('giving.flash.system_error', admin_email: Setting.get(:contact, :bug_notification_email))
      log_error "Authentication Error", e      
    rescue Stripe::APIConnectionError => e
      flash[:error] = t('giving.flash.generic_error')
    rescue Stripe::StripeError => e
      flash[:error] = t('giving.flash.generic_error')
    rescue => e
      flash[:error] = t('giving.flash.system_error', admin_email: Setting.get(:contact, :bug_notification_email))
      log_error "Generic Error", e      
    end

    redirect_to new_giving_transaction_path
    end

  private

  def log_error(type, e)
    body = e.json_body
    err = body[:error]
    logger.info "Donation Transaction Exception: #{type}: #{err[:message]}\n#{e.backtrace.join('\n')}"
  end
end
