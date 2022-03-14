class NpiRegistryService
  REGISTRY_API_URL = 'https://npiregistry.cms.hhs.gov/api/'

  # Fetch data from registry API
  # Return a ProviderInfo object
  # Return nil if provider not found
  def fetch_from_registry(number)
    begin
      params = {
        params: {
          version: '2.1',
          number: number
        }
      }
      response = RestClient.get REGISTRY_API_URL, params
      body = JSON.parse(response.body)
      results = body['results']
      result = results.first if results
    rescue RestClient::ExceptionWithResponse => err
      result = nil
    end

    make_provider_info_from_json(result)
  end

  # Fetch ProviderInfo by NPI#
  # Return a ProviderInfo
  # Try to read from provider_info table first
  # Fetch from registry otherwise
  # accessed_at will always be updated to the current time
  def fetch_by_npi(number)
    pp (ProviderInfo.where(number: number))
    info = ProviderInfo.where(number: number).first
    info = fetch_from_registry(number) if info.nil?

    if info then
      info.accessed_at = Time.now
      info.save
    end

    info
  end

  def get_best_address(addresses)
    addresses.find {|addr| addr['address_purpose'] == 'LOCATION'}
  end

  def get_best_taxonomy(taxonomies)
    taxonomies.find {|tax| tax['primary']}
  end

  # Create a ProviderInfo object from single result from registry
  def make_provider_info_from_json(result)
    return nil if result.nil?

    number = result.dig('number').to_s
    display_name = result.dig('basic', 'name')

    addr = get_best_address(result['addresses'])
    if !addr.blank? then
      line2 = addr['address_2']
      first = line2.blank? ?
        "#{addr['address_1']}" :
        "#{addr['address_1']}\n#{addr['address_2']}"
      last = "#{addr['city']}, #{addr['state']} #{addr['postal_code']}"
      display_address = "#{first}\n#{last}"
    else
      display_address = 'N/A'
    end

    tax = get_best_taxonomy(result['taxonomies'])
    if !tax.blank? then
      display_taxonomy = "#{tax['desc']} (#{tax['code']})"
    else
      display_taxonomy = 'N/A'
    end

    ProviderInfo.new(
        number: number,
        display_name: display_name,
        display_address: display_address,
        display_taxonomy: display_taxonomy)
  end
end
