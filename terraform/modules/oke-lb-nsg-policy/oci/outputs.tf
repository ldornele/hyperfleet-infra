output "policy_id" {
  description = "OCID of the IAM policy granting the OKE cluster NSG management permissions."
  value       = oci_identity_policy.oke_lb_nsg.id
}
