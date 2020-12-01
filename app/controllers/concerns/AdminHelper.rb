module AdminHelper

  def is_admin_session_expired?(admin)

    if DateTime.now.utc > admin.expire_at

      true

    else

      next_expire_at = Rails.env.development? ? DateTime.now.utc + 24.hours : DateTime.now.utc + 15.minutes

      admin.update!(expire_at: next_expire_at)

      false

    end

  end

end