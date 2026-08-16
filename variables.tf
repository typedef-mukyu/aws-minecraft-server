variable "ec2_type" {
  description = "The EC2 instance's type"
  type        = string
  default     = "t3.small"
}

variable "ssh_allowed_ip" {
  description = "The IP range from which SSH is allowed from"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
  description = "The SSH public key to use for this server"
  type        = string
  default     = ""
}

variable "ec2_user_data_b64" {
  description = "The user data string to pass to the EC2 instance"
  type        = string
  default     = ""
}