resource "oci_identity_policy" "oke_lb_nsg" {
  compartment_id = var.compartment_id
  name           = "hyperfleet-oke-lb-nsg-policy"
  description    = "Lets the OKE cloud controller manager create and manage the frontend NSG for LoadBalancer services (architecture ADR 0024)."

  statements = [
    "allow any-user to manage network-security-groups in compartment id ${var.compartment_id} where request.principal.type = 'cluster'",
    "allow any-user to manage virtual-network-family in compartment id ${var.compartment_id} where request.principal.type = 'cluster'",
  ]

  freeform_tags = var.freeform_tags
}
