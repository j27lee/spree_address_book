class Spree::AddressesController < Spree::StoreController
  helper Spree::AddressesHelper
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  load_and_authorize_resource :class => Spree::Address

  def index
    @addresses = spree_current_user.addresses
  end

  def show
    redirect_to account_path
  end

  def edit
    session["spree_user_return_to"] = request.env['HTTP_REFERER']
  end

  def new
    @address = Spree::Address.default
  end

  def update
    if @address.editable?
      if @address.update_attributes(address_params)
        flash[:notice] = Spree.t(:successfully_updated, :resource => Spree.t(:address, scope: "address_book"))
        redirect_back_or_default(account_path)
      else
        render :action => "edit"
      end
    else
      new_address = @address.clone
      new_address.attributes = address_params
      @address.update_attribute(:deleted_at, Time.now)
      if new_address.save
        flash[:notice] = Spree.t(:successfully_updated, :resource => Spree.t(:address, scope: "address_book"))
        redirect_back_or_default(account_path)
      else
        render :action => "edit"
      end
    end
  end

  def create
    @address = spree_current_user.addresses.build(address_params)
    @address.user = try_spree_current_user
    if @address.save
      flash[:notice] = Spree.t(:successfully_created, :resource => Spree.t(:address, scope: "address_book"))
      redirect_to account_path
    else
      render :action => "new"
    end
  end

  def destroy
    @address.destroy

    flash[:notice] = Spree.t(:successfully_removed, :resource => t(:address, scope: "address_book"))
    redirect_to(request.env['HTTP_REFERER'] || account_path) unless request.xhr?
  end

end

def address_params
  params.require(:address).permit(:firstname, :lastname, :address1, :address2, :city, :state_id, :zipcode, :country_id, :phone)
end
