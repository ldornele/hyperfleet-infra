variable "compartment_id" {
  description = "OCID of the compartment that will contain the OKE cluster and its VCN."
  type        = string
}

variable "freeform_tags" {
  description = "Freeform tags applied to the policy."
  type        = map(string)
  default     = {}
}
