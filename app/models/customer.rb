class Customer < User


    before_create :set_user_type
    has_one :customer_user
    validates_presence_of :customer_user
    accepts_nested_attributes_for :customer_user,
                                  allow_destroy: true,
                                  reject_if: :reject_customer_user


    private


    def reject_customer_user(attributes)
        attributes['full_name'].blank? || attributes['date_of_birth'].blank? || attributes['residential_address'].blank? || attributes['gender'].blank? || attributes['country_of_residence'].blank?
    end

    def set_user_type
        self.user_type = 0
    end



end