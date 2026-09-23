module "ci_compartment" {
  source                = "../modules/compartment/oci"
  parent_compartment_id = var.team_compartment_id
  freeform_tags         = local.tags
}

module "ci_quota" {
  source       = "../modules/quota/oci"
  tenancy_ocid = var.tenancy_ocid
  statements   = var.quota_statements

  freeform_tags = local.tags

  depends_on = [module.ci_compartment]
}

module "ci_budget" {
  source                = "../modules/budget/oci"
  tenancy_ocid          = var.tenancy_ocid
  target_compartment_id = module.ci_compartment.id
  amount                = var.budget_amount
  alert_recipients      = var.budget_alert_recipients

  freeform_tags = local.tags
}

module "ci_sweep" {
  source                = "../modules/lifecycle/oci"
  tenancy_ocid          = var.tenancy_ocid
  compartment_id        = module.ci_compartment.id
  function_image        = var.sweep_function_image
  function_image_digest = var.sweep_function_image_digest

  run_window_hours    = var.sweep_run_window_hours
  dry_run             = var.sweep_dry_run
  schedule_recurrence = var.sweep_schedule_recurrence

  freeform_tags = local.tags
}

resource "terraform_data" "postgresql_regional_durability_check" {
  count = var.postgresql_enabled ? 1 : 0

  lifecycle {
    precondition {
      condition     = !(var.postgresql_storage_is_regionally_durable && var.region == "us-sanjose-1")
      error_message = "postgresql_storage_is_regionally_durable cannot be true in us-sanjose-1 (single availability domain). Set to false or use a multi-AD region."
    }
  }
}

module "managed_postgresql" {
  count = var.postgresql_enabled ? 1 : 0

  source            = "../modules/postgresql/oci"
  compartment_id    = var.postgresql_compartment_id
  ci_compartment_id = module.ci_compartment.id
  tenancy_ocid      = var.tenancy_ocid
  subnet_id         = var.postgresql_subnet_id

  display_name                  = var.postgresql_display_name
  db_version                    = var.postgresql_db_version
  shape                         = var.postgresql_shape
  instance_ocpu_count           = var.postgresql_instance_ocpu_count
  instance_memory_size_in_gbs   = var.postgresql_instance_memory_size_in_gbs
  instance_count                = var.postgresql_instance_count
  availability_domain           = var.postgresql_availability_domain
  storage_is_regionally_durable = var.postgresql_storage_is_regionally_durable
  admin_username                = var.postgresql_admin_username
  admin_password_secret_id      = var.postgresql_admin_password_secret_id
  admin_password_secret_version = var.postgresql_admin_password_secret_version
  nsg_ids                       = var.postgresql_nsg_ids
  backup_retention_days         = var.postgresql_backup_retention_days
  backup_start                  = var.postgresql_backup_start

  freeform_tags = {
    "hyperfleet-managed-by" = "terraform"
    "hyperfleet-purpose"    = "oci-deployment-path-postgresql"
  }

  depends_on = [terraform_data.postgresql_regional_durability_check]
}

module "oke_lb_nsg_policy" {
  count = var.oke_lb_nsg_policy_enabled ? 1 : 0

  source         = "../modules/oke-lb-nsg-policy/oci"
  compartment_id = var.oke_compartment_id

  freeform_tags = {
    "hyperfleet-managed-by" = "terraform"
    "hyperfleet-purpose"    = "oke-lb-security"
  }
}

locals {
  tags = {
    "hyperfleet-managed-by" = "terraform"
    "hyperfleet-purpose"    = "ci"
  }
}
