class ProvidersController < ApplicationController
  def initialize
    super
    @npi_registry_service = NpiRegistryService.new
  end

  def index
    @provider_infos = ProviderInfo.all.order(accessed_at: :desc)
    @error_msg = params[:error_msg]
  end

  def lookup
    info = @npi_registry_service.fetch_by_npi(params[:number])
    if info then
      redirect_to :action => 'index'
    else
      redirect_to :action => 'index', :params => { error_msg: 'Could not lookup NPI#' }
    end
  end
end
