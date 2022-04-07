/**
 * Copyright 2022 The Sigstore Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "project_id" {
  type    = string
  default = ""
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Must specify project_id variable."
  }
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-west1"
}

variable "cluster_name" {
  type    = string
  default = "sigstore-staging"
}

variable "name" {
  description = "KMS KeyRing name"
  type        = string
  default     = "rekor-keyring"
}

variable "location" {
  type    = string
  default = "global"
}

variable "key_name" {
  description = "KMS Key name"
  type        = string
  default     = "rekor-key"
}
