# Copyright:: Copyright (c) 2014 Bitpusher LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'net/http'

Ohai.plugin(:SoftLayer) do
  provides "softlayer"

  SOFTLAYER_METADATA_ADDR = 'api.service.softlayer.com'
  SOFTLAYER_METADATA_API = '/rest/v3/SoftLayer_Resource_Metadata/'
  SOFTLAYER_METADATA_KEYS = %w{
    backend_mac_addresses
    datacenter
    datacenter_id
    domain
    frontend_mac_addresses
    fully_qualified_domain_name
    hostname
    id
    primary_backend_ip_address
    primary_ip_address
    provision_state
    router
    tags
    user_metadata
    vlan_ids
    vlans
    service_resource
    service_resources
  }

  # For bare metal there is no way to auto-detect
  # TODO: Check the MACs on SoftLayer Virtual
  def looks_like_softlayer?
    hint?('softlayer')
  end

  def softlayey_key(key)
    'get' + key.split('_').map(&:capitalize!).join('')
  end

  def http_client
    Net::HTTP.start(SOFTLAYER_METADATA_ADDR, 443).tap do |h|
      h.read_timeout = 600
      h.use_ssl = true
      h.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end

  collect_data do
    if looks_like_softlayer?
      softlayer Mash.new
      SOFTLAYER_METADATA_KEYS.each do |key|
        softlayer[key] = http_client.get(SOFTLAYER_METADATA_API + softlayey_key(key))
      end
      # Standard keys to make life a little easier
      softlayer[:public_ipv4] = softlayer[:primary_ip_address]
      softlayer[:local_ipv4] = softlayer[:primary_backend_ip_address]
    end
  end

end
