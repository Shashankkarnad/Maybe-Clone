class PropertiesController < ApplicationController
  before_action :set_account, only: [ :update, :show ]

  def new
    @account = Current.family.accounts.properties.build(
      currency: Current.family.currency
    )
  end

  def show
  end

  def create
    account = Current.family.accounts.create_and_sync(account_params)
    redirect_to account, notice: t(".success")
  end

  def update
    @account.update_with_sync!(account_params)
    redirect_to @account, notice: t(".success")
  end

  private

    def set_account
      @account = Current.family.accounts.properties.find_by(accountable_id: params[:id])
    end

    def account_params
      params.require(:account)
        .permit(
          :name, :balance, :institution_id, :currency, :accountable_type,
          accountable_attributes: [
            :id,
            :year_built,
            :area_unit,
            :area_value,
            address_attributes: [ :line1, :line2, :locality, :region, :country, :postal_code ]
          ]
        )
    end
end
