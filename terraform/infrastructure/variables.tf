variable "APPLICATION_KEY" {
  description = "The application key for Backblaze B2"
  type        = string
}

variable "APPLICATION_KEY_ID" {
  description = "The application key id for Backblaze B2"
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket to create in Backblaze B2"
  type        = string
  default     = "pmhme-backup"

}
