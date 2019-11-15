class Store < User
    
    before_destroy :destroy_store_user
    has_one :store_user
    validates_presence_of :store_user
    accepts_nested_attributes_for :store_user,
                                  allow_destroy: true,
                                  reject_if: :reject_store_user

    private

    def reject_store_user(attributes)
        attributes['store_owner_full_name'].blank? || attributes['store_owner_work_number'].blank? || attributes['store_name'].blank? || attributes['store_address'].blank? || attributes['store_number'].blank? || attributes['store_country'].blank? || attributes['store_business_license'].blank?
    end

    def destroy_store_user
        self.store_user.destroy
    end

end