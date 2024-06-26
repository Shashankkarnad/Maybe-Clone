class TransactionsController < ApplicationController
  layout "with_sidebar"

  def index
    @q = search_params
    result = Current.family.transactions.search(@q).ordered
    @pagy, @transactions = pagy(result, items: params[:per_page] || "10")

    @totals = {
      count: result.select { |t| t.currency == Current.family.currency }.count,
      income: result.income_total(Current.family.currency).abs,
      expense: result.expense_total(Current.family.currency)
    }
  end

  def new
    @transaction = Account::Transaction.new.tap do |txn|
      if params[:account_id]
        txn.account = Current.family.accounts.find(params[:account_id])
      end
    end
  end

  def create
    @transaction = Current.family.accounts
                          .find(params[:transaction][:account_id])
                          .transactions
                          .create!(transaction_params.merge(amount: amount))

    @transaction.sync_account_later
    redirect_back_or_to account_path(@transaction.account), notice: t(".success")
  end

  def bulk_delete
    destroyed = Current.family.transactions.destroy_by(id: bulk_delete_params[:transaction_ids])
    redirect_back_or_to transactions_url, notice: t(".success", count: destroyed.count)
  end

  def bulk_edit
  end

  def bulk_update
    transactions = Current.family.transactions.where(id: bulk_update_params[:transaction_ids])
    if transactions.update_all(bulk_update_params.except(:transaction_ids).to_h.compact_blank!)
      redirect_back_or_to transactions_url, notice: t(".success", count: transactions.count)
    else
      flash.now[:error] = t(".failure")
      render :index, status: :unprocessable_entity
    end
  end

  def mark_transfers
    Current.family
           .transactions
           .where(id: bulk_update_params[:transaction_ids])
           .mark_transfers!

    redirect_back_or_to transactions_url, notice: t(".success")
  end

  def unmark_transfers
    Current.family
           .transactions
           .where(id: bulk_update_params[:transaction_ids])
           .update_all marked_as_transfer: false

    redirect_back_or_to transactions_url, notice: t(".success")
  end

  private

    def amount
      if nature.income?
        transaction_params[:amount].to_d * -1
      else
        transaction_params[:amount].to_d
      end
    end

    def nature
      params[:transaction][:nature].to_s.inquiry
    end

    def bulk_delete_params
      params.require(:bulk_delete).permit(transaction_ids: [])
    end

    def bulk_update_params
      params.require(:bulk_update).permit(:date, :notes, :excluded, :category_id, :merchant_id, transaction_ids: [])
    end

    def search_params
      params.fetch(:q, {}).permit(:start_date, :end_date, :search, accounts: [], account_ids: [], categories: [], merchants: [])
    end

    def transaction_params
      params.require(:transaction).permit(:name, :date, :amount, :currency, :category_id, tag_ids: [])
    end
end
