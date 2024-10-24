class ApplicationController < ActionController::Base
  include Onboardable, Localize, AutoSync, Authentication, Invitable, SelfHostable, StoreLocation, Impersonatable
  include Pagy::Backend

  helper_method :require_upgrade?

  private
    def require_upgrade?
      Current.family && !Current.family.subscribed? && !self_hosted? && request.path != settings_billing_path
    end

    def with_sidebar
      return "turbo_rails/frame" if turbo_frame_request?

      "with_sidebar"
    end
end
