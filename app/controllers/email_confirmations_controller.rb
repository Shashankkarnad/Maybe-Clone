class EmailConfirmationsController < ApplicationController
  skip_before_action :set_request_details, only: :confirm
  skip_authentication only: :confirm

  def confirm
    @user = User.find_by_token_for(:email_confirmation, params[:token])

    if @user&.confirm_email_change(@user.email_confirmation_token)
      if Current.user == @user
        redirect_to settings_profile_path, notice: t(".success")
      else
        redirect_to new_session_path, notice: t(".success_login")
      end
    else
      redirect_to root_path, alert: t(".invalid_token")
    end
  end
end
