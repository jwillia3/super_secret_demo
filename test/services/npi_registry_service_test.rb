require "test_helper"

class NpiRegistryServiceTest < ActiveSupport::TestCase

  #TODO: Figure out how to make this into a fixture-like file
  def NpiRegistryServiceTest.LUARA_SAMPLE_JSON
    <<-EOF
      {
        "result_count": 1,
        "results": [
          {
            "enumeration_type": "NPI-1",
            "number": 1245319599,
            "last_updated_epoch": 1351814400,
            "created_epoch": 1162771200,
            "basic": {
              "name_prefix": "DR.",
              "first_name": "LAURA",
              "last_name": "SAMPLE",
              "middle_name": "TURTZO",
              "credential": "MD",
              "sole_proprietor": "NO",
              "gender": "F",
              "enumeration_date": "2006-11-06",
              "last_updated": "2012-11-02",
              "status": "A",
              "name": "SAMPLE LAURA"
            },
            "other_names": [],
            "addresses": [
              {
                "country_code": "US",
                "country_name": "United States",
                "address_purpose": "LOCATION",
                "address_type": "DOM",
                "address_1": "1080 FIRST COLONIAL RD",
                "address_2": "SUITE 200",
                "city": "VIRGINIA BEACH",
                "state": "VA",
                "postal_code": "234542406",
                "telephone_number": "757-395-6070",
                "fax_number": "757-395-6381"
              },
              {
                "country_code": "US",
                "country_name": "United States",
                "address_purpose": "MAILING",
                "address_type": "DOM",
                "address_1": "1080 FIRST COLONIAL RD",
                "address_2": "SUITE 200",
                "city": "VIRGINIA BEACH",
                "state": "VA",
                "postal_code": "234542406",
                "telephone_number": "757-395-6070",
                "fax_number": "757-395-6381"
              }
            ],
            "taxonomies": [
              {
                "code": "207Q00000X",
                "desc": "Family Medicine",
                "primary": true,
                "state": "VA",
                "license": "0101244988"
              }
            ],
            "identifiers": []
          }
        ]
      }
EOF
  end



  def NpiRegistryServiceTest.LAURA_SAMPLE
    JSON.parse(NpiRegistryServiceTest.LUARA_SAMPLE_JSON)
  end

  def laura_sample_rest_client_mock(succeed: true)
    mock = Minitest::Mock.new
    mock.expect :body, NpiRegistryServiceTest.LUARA_SAMPLE_JSON
    mock
  end



  test '#get_best_address gets address purpose LOCATION' do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first

    best = npi_registry_service.get_best_address(json['addresses'])
    assert_not_nil best
    assert_equal best['address_purpose'], 'LOCATION'
  end

  test '#make_provider_info_from_json returns N/A if no LOCATION address' do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first.clone

    # Remove all LOCATION addresses
    json['addresses'].filter! {|addr| addr['address_purpose'] != 'LOCATION'}

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_address, 'N/A'
  end

  test '#make_provider_info_from_json returns N/A if no addresses' do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first.clone

    # Remove all addresses
    json['addresses'] = []

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_address, 'N/A'
  end

  test '#make_provider_info_from_json handles 3-line addresses' do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first.clone

    best = npi_registry_service.get_best_address(json['addresses'])
    assert_not_nil best
    assert_not best['address_2'].blank?

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_address, "1080 FIRST COLONIAL RD\nSUITE 200\nVIRGINIA BEACH, VA 234542406"
  end

  test '#make_provider_info_from_json handles 2-line addresses' do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first.clone

    best = npi_registry_service.get_best_address(json['addresses'])
    assert_not_nil best
    best['address_2'] = ''

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_address, "1080 FIRST COLONIAL RD\nVIRGINIA BEACH, VA 234542406"

    # Make sure nil does not throw
    best['address_2'] = nil

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_address, "1080 FIRST COLONIAL RD\nVIRGINIA BEACH, VA 234542406"
  end

  test "#make_provider_info_from_json gets correct number" do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.number, json['number'].to_s
  end

  test "#make_provider_info_from_json gets correct name" do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_name, json.dig('basic', 'name')
  end

  test "#make_provider_info_from_json gets correct taxonomy" do
    npi_registry_service = NpiRegistryService.new
    json = NpiRegistryServiceTest.LAURA_SAMPLE['results'].first

    info = npi_registry_service.make_provider_info_from_json(json)
    assert_equal info.display_taxonomy, 'Family Medicine (207Q00000X)'
  end

  #TODO: check for blank taxonomy
  #TODO: check for nil taxonomy

  test '#fetch_from_registry calls API' do
    mock = laura_sample_rest_client_mock

    #TODO: Check that the url is correct
    #TODO: Check that the params are correct

    RestClient.stub :get, mock do
      npi_registry_service = NpiRegistryService.new
      info = npi_registry_service.fetch_from_registry('1245319599')
      assert_not_nil info
      assert_equal info.number, '1245319599'
    end
  end

  #TODO: #fetch_by_npi prefers cached results
  #TODO: #fetch_by_npi calls #fetch_from_registry
  #TODO: #fetch_by_npi handles HTTP errors
end
