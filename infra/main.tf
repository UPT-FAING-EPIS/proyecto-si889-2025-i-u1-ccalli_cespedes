terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0.0"
    }
  }
  required_version = ">= 0.14.9"
}

variable "suscription_id" {
  type        = string
  description = "452059b4-1dbe-460c-9ef6-85738d616b22"
}

variable "sqladmin_username" {
  type        = string
  description = "Administrator username for server"
}

variable "sqladmin_password" {
  type        = string
  description = "Administrator password for server"
}

provider "azurerm" {
  features {}
  subscription_id = var.suscription_id
}

# Grupo de recursos para el sistema de recomendación de carreras
resource "azurerm_resource_group" "rg" {
  name     = "upt-arg-carreras"
  location = "brazilsouth"
}

# Plan de servicio para la aplicación web
resource "azurerm_service_plan" "appserviceplan" {
  name                = "upt-asp-carreras"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1"
}

# Aplicación Web principal en .NET 8.0
resource "azurerm_linux_web_app" "webapp" {
  name                = "upt-awa-carreras"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.appserviceplan.id
  depends_on          = [azurerm_service_plan.appserviceplan]

  site_config {
    minimum_tls_version = "1.2"
    always_on           = false
    application_stack {
      dotnet_version = "8.0"
    }
  }
}

# Servidor SQL Server para el sistema de recomendación
resource "azurerm_mssql_server" "sqlsrv" {
  name                         = "upt-dbs-carreras"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sqladmin_username
  administrator_login_password = var.sqladmin_password
}

# Regla de firewall para permitir conexiones públicas (ajustar en producción)
resource "azurerm_mssql_firewall_rule" "sqlaccessrule" {
  name             = "PublicAccess"
  server_id        = azurerm_mssql_server.sqlsrv.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# Base de datos principal del sistema
resource "azurerm_mssql_database" "sqldb" {
  name      = "RecomCarrerasDB"
  server_id = azurerm_mssql_server.sqlsrv.id
  sku_name  = "Free"
}
