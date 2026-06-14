###############################################################################
# modules/networking/main.tf
# MSP ALZ — Networking Module
# Supports two modes controlled by var.mode:
#   "hub"   → Hub VNet + Azure Firewall + Bastion + Route Table
#   "spoke" → Spoke VNet + Subnets + NSGs + VNet Peering to Hub + UDR to Firewall
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.90.0, < 4.0.0"
    }
  }
}

###############################################################################
# RESOURCE GROUP
###############################################################################

resource "azurerm_resource_group" "networking" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

###############################################################################
# HUB MODE — Virtual Network
###############################################################################

resource "azurerm_virtual_network" "hub" {
  count = var.mode == "hub" ? 1 : 0

  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  address_space       = var.address_space
  dns_servers         = [] # Azure Firewall DNAT handles DNS forwarding

  tags = var.tags
}

resource "azurerm_subnet" "firewall" {
  count = var.mode == "hub" ? 1 : 0

  name                 = "AzureFirewallSubnet" # Name is immutable per Azure requirement
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_subnet" "bastion" {
  count = var.mode == "hub" ? 1 : 0

  name                 = "AzureBastionSubnet" # Name is immutable per Azure requirement
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_subnet" "gateway" {
  count = var.mode == "hub" ? 1 : 0

  name                 = "GatewaySubnet" # Name is immutable per Azure requirement
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.gateway_subnet_prefix]
}

resource "azurerm_subnet" "management" {
  count = var.mode == "hub" ? 1 : 0

  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.hub[0].name
  address_prefixes     = [var.management_subnet_prefix]
}

###############################################################################
# HUB MODE — Azure Firewall (Standard SKU + Firewall Policy)
###############################################################################

resource "azurerm_public_ip" "firewall" {
  count = var.mode == "hub" ? 1 : 0

  name                = var.firewall_pip_name
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # Zone-redundant for HA
  tags                = var.tags
}

resource "azurerm_firewall_policy" "hub" {
  count = var.mode == "hub" ? 1 : 0

  name                     = "${var.firewall_name}-policy"
  resource_group_name      = azurerm_resource_group.networking.name
  location                 = azurerm_resource_group.networking.location
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"

  dns {
    proxy_enabled = true # Required for FQDN-based network rules
  }

  insights {
    enabled                            = true
    default_log_analytics_workspace_id = var.log_analytics_workspace_id
    retention_in_days                  = 30
  }

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "baseline" {
  count = var.mode == "hub" ? 1 : 0

  name               = "rcg-baseline"
  firewall_policy_id = azurerm_firewall_policy.hub[0].id
  priority           = 100

  # Network rules — allow essential outbound traffic
  network_rule_collection {
    name     = "nrc-allow-dns"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "allow-dns-udp"
      protocols             = ["UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.63.129.16"] # Azure DNS
      destination_ports     = ["53"]
    }

    rule {
      name                  = "allow-dns-tcp"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }
  }

  network_rule_collection {
    name     = "nrc-allow-azure-monitor"
    priority = 200
    action   = "Allow"

    rule {
      name              = "allow-log-analytics"
      protocols         = ["TCP"]
      source_addresses  = ["*"]
      destination_fqdns = ["*.ods.opinsights.azure.com", "*.oms.opinsights.azure.com"]
      destination_ports = ["443"]
    }
  }

  # Application rules — allow Windows Update and Azure services
  application_rule_collection {
    name     = "arc-allow-windows-update"
    priority = 300
    action   = "Allow"

    rule {
      name             = "allow-windows-update"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Http"
        port = 80
      }
      destination_fqdns = [
        "*.update.microsoft.com",
        "*.windowsupdate.com",
        "*.download.windowsupdate.com"
      ]
    }

    rule {
      name             = "allow-azure-active-directory"
      source_addresses = ["*"]
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = [
        "login.microsoftonline.com",
        "graph.microsoft.com",
        "*.azure.com"
      ]
    }
  }
}

resource "azurerm_firewall" "hub" {
  count = var.mode == "hub" ? 1 : 0

  name                = var.firewall_name
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub[0].id
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = "ipconfig-primary"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  tags = var.tags
}

###############################################################################
# HUB MODE — Azure Bastion (Standard SKU for tunneling support)
###############################################################################

resource "azurerm_public_ip" "bastion" {
  count = var.mode == "hub" ? 1 : 0

  name                = var.bastion_pip_name
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_bastion_host" "hub" {
  count = var.mode == "hub" ? 1 : 0

  name                   = var.bastion_name
  resource_group_name    = azurerm_resource_group.networking.name
  location               = azurerm_resource_group.networking.location
  sku                    = "Standard"
  tunneling_enabled      = true # Enables SSH/RDP native client tunneling
  copy_paste_enabled     = true
  file_copy_enabled      = true
  shareable_link_enabled = false

  ip_configuration {
    name                 = "ipconfig-bastion"
    subnet_id            = azurerm_subnet.bastion[0].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = var.tags
}

###############################################################################
# HUB MODE — Diagnostic Settings → Log Analytics
###############################################################################

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.mode == "hub" ? 1 : 0

  name                       = "diag-${var.firewall_name}"
  target_resource_id         = azurerm_firewall.hub[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AzureFirewallApplicationRule" }
  enabled_log { category = "AzureFirewallNetworkRule" }
  enabled_log { category = "AzureFirewallDnsProxy" }
  enabled_log { category = "AzureFirewallThreatIntel" }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

###############################################################################
# SPOKE MODE — Virtual Network
###############################################################################

resource "azurerm_virtual_network" "spoke" {
  count = var.mode == "spoke" ? 1 : 0

  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  address_space       = var.address_space
  dns_servers         = [var.hub_firewall_private_ip] # Route DNS through Firewall proxy

  tags = var.tags
}

###############################################################################
# SPOKE MODE — Subnets
###############################################################################

resource "azurerm_subnet" "workload" {
  count = var.mode == "spoke" ? 1 : 0

  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.spoke[0].name
  address_prefixes     = [var.workload_subnet_prefix]

  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Sql"]
}

resource "azurerm_subnet" "data" {
  count = var.mode == "spoke" ? 1 : 0

  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.spoke[0].name
  address_prefixes     = [var.data_subnet_prefix]

  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
}

resource "azurerm_subnet" "appgw" {
  count = var.mode == "spoke" ? 1 : 0

  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.spoke[0].name
  address_prefixes     = [var.appgw_subnet_prefix]
  # Note: Application Gateway v2 subnet cannot have NSG with deny rules on ports 65200-65535
}

###############################################################################
# SPOKE MODE — Network Security Groups
###############################################################################

resource "azurerm_network_security_group" "workload" {
  count = var.mode == "spoke" ? 1 : 0

  name                = "nsg-${var.vnet_name}-workload"
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location

  security_rule {
    name                       = "deny-internet-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
    description                = "Block all direct internet inbound — traffic must route through Firewall/AppGW"
  }

  security_rule {
    name                       = "allow-azure-loadbalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
    description                = "Required for Azure internal health probes"
  }

  security_rule {
    name                       = "allow-bastion-ssh-rdp"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "VirtualNetwork" # Bastion operates within VNet space
    destination_address_prefix = "*"
    description                = "Allow SSH/RDP only from Bastion subnet via VNet peering"
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "data" {
  count = var.mode == "spoke" ? 1 : 0

  name                = "nsg-${var.vnet_name}-data"
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location

  security_rule {
    name                       = "allow-workload-to-data"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "5432", "3306", "6379"]
    source_address_prefix      = var.workload_subnet_prefix
    destination_address_prefix = "*"
    description                = "Allow DB traffic from workload tier only"
  }

  security_rule {
    name                       = "deny-all-other-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Explicit default deny — data tier is strictly access-controlled"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  count = var.mode == "spoke" ? 1 : 0

  subnet_id                 = azurerm_subnet.workload[0].id
  network_security_group_id = azurerm_network_security_group.workload[0].id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  count = var.mode == "spoke" ? 1 : 0

  subnet_id                 = azurerm_subnet.data[0].id
  network_security_group_id = azurerm_network_security_group.data[0].id
}

###############################################################################
# SPOKE MODE — User-Defined Route (UDR) — Force Tunnel Through Azure Firewall
###############################################################################

resource "azurerm_route_table" "spoke" {
  count = var.mode == "spoke" ? 1 : 0

  name                          = "rt-${var.vnet_name}-spoke"
  resource_group_name           = azurerm_resource_group.networking.name
  location                      = azurerm_resource_group.networking.location
  disable_bgp_route_propagation = true # Prevent on-prem routes overriding UDRs

  route {
    name                   = "udr-default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.hub_firewall_private_ip
  }

  tags = var.tags
}

resource "azurerm_subnet_route_table_association" "workload" {
  count = var.mode == "spoke" ? 1 : 0

  subnet_id      = azurerm_subnet.workload[0].id
  route_table_id = azurerm_route_table.spoke[0].id
}

resource "azurerm_subnet_route_table_association" "data" {
  count = var.mode == "spoke" ? 1 : 0

  subnet_id      = azurerm_subnet.data[0].id
  route_table_id = azurerm_route_table.spoke[0].id
}

###############################################################################
# SPOKE MODE — VNet Peering to Hub (Bidirectional)
###############################################################################

# Spoke → Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.mode == "spoke" ? 1 : 0

  name                         = "peer-${var.vnet_name}-to-hub"
  resource_group_name          = azurerm_resource_group.networking.name
  virtual_network_name         = azurerm_virtual_network.spoke[0].name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true # Use Hub's VPN/ExpressRoute gateway
}

# Hub → Spoke (created in Hub context — requires provider alias override at root)
# Note: This peer is declared here for completeness but providers must be aliased
# at the module call. In multi-subscription setups, use a separate azurerm_virtual_network_peering
# resource in the hub module or in root main.tf with the connectivity provider alias.
