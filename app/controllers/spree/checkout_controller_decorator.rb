Spree::CheckoutController.class_eval do
  helper Spree::AddressesHelper

  before_filter :set_addresses, :only => :update
  before_filter :add_address_ids_to_permitted_attributes, :only => :update

  after_filter :set_address_user_ids, :only => :update
  after_filter :normalize_addresses, :only => :update

  protected

    def set_addresses
      return unless params[:order] && params[:state] == "address"
      if params[:order][:ship_address_id].to_i > 0
        params[:order].delete(:ship_address_attributes)
        Spree::Address.find(params[:order][:ship_address_id]).user_id != spree_current_user.id && raise("Frontend address forging")
      else
        params[:order].delete(:ship_address_id)
      end

      if params[:order][:bill_address_id].to_i > 0
        params[:order].delete(:bill_address_attributes)
        bill = Spree::Address.find(params[:order][:bill_address_id])
        bill.user_id != spree_current_user.id && raise("Frontend address forging")
        @order.bill_address = bill;
        @order.bill_address.save;
      else
        params[:order].delete(:bill_address_id)
      end

    end

    def normalize_addresses
      return unless params[:state] == "address" && @order.bill_address_id && @order.ship_address_id
      return if (@order.bill_address.id.nil? || @order.ship_address.nil?)

      @order.bill_address.reload
      @order.ship_address.reload

      # ensure that there is no validation errors and addresses was saved
      return unless @order.bill_address && @order.ship_address
      if @order.bill_address_id != @order.ship_address_id && @order.bill_address.same_as?(@order.ship_address)
        @order.bill_address.destroy
        @order.update_attribute(:bill_address, @order.ship_address)
      end
    end

    def set_address_user_ids
      @order.bill_address.update_attribute(:user_id, try_spree_current_user.try(:id)) if @order.bill_address_id
      @order.ship_address.update_attribute(:user_id, try_spree_current_user.try(:id)) if @order.ship_address_id
    end

    def add_address_ids_to_permitted_attributes
      [:bill_address_id, :ship_address_id].each do |attrib|
        Spree::PermittedAttributes.checkout_attributes << attrib unless Spree::PermittedAttributes.checkout_attributes.include?(attrib)
      end
    end
end
