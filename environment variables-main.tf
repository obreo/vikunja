# 1 - Secret value
variable "env-name-a" {
  description = ""
  type        = string
  default     = "VIKUNJA_DATABASE_USER"
}
variable "env-value-a" {
  description = ""
  type        = string
  default     = "" # application env name > application value is registered by SSM
}

# 2 - Secret value
variable "env-name-b" {
  description = ""
  type        = string
  default     = "VIKUNJA_DATABASE_PASSWORD"
}
variable "env-value-b" {
  description = ""
  type        = string
  default     = "" # application env name > application value is registered by SSM
}

# 3
variable "env-name-c" {
  description = ""
  type        = string
  default     = "VIKUNJA_DATABASE_HOST"
}
variable "env-value-c" {
  description = ""
  type        = string
  default     = "" # application env name > application value is registered by RDS
}


# 4
variable "env-name-d" {
  description = ""
  type        = string
  default     = "VIKUNJA_DATABASE_TYPE"
}
variable "env-value-d" {
  description = ""
  type        = string
  default     = "mysql"
}


# 5
variable "env-name-e" {
  description = ""
  type        = string
  default     = "VIKUNJA_SERVICE_PUBLICURL"
}
variable "env-value-e" {
  description = ""
  type        = string
  default     = "" # application env name > appliaction value assigned s3 endpoint
}

# 6
variable "env-name-f" {
  description = ""
  type        = string
  default     = "VIKUNJA_DATABASE_DATABASE"
}
variable "env-value-f" {
  description = ""
  type        = string
  default     = "vikunja"
}


# 7
variable "env-name-g" {
  description = ""
  type        = string
  default     = "VIKUNJA_CORS_ENABLE"
}
variable "env-value-g" {
  description = ""
  type        = string
  default     = "true"
}
