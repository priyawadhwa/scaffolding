// Private network
module "network" {
  source = "../network"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name
}

// Bastion
module "bastion" {
  source = "../bastion"

  project_id         = var.project_id
  region             = var.region
  network            = module.network.network_name
  subnetwork         = module.network.subnetwork_self_link
  tunnel_accessor_sa = var.tunnel_accessor_sa

  depends_on = [
    module.network
  ]
}

module "tuf" {
  source = "../tuf"

  region     = var.region
  project_id = var.project_id

  tuf_bucket = var.tuf_bucket
}

// Monitoring
module "monitoring" {
  source = "../monitoring"

  // Disable module entirely if monitoring
  // is disabled
  count = var.monitoring.enabled ? 1 : 0

  project_id              = var.project_id
  cluster_location        = var.project_id
  cluster_name            = var.cluster_name
  ca_pool_name            = var.ca_pool_name
  fulcio_url              = var.monitoring.fulcio_url
  rekor_url               = var.monitoring.rekor_url
  dex_url                 = var.monitoring.dex_url
  notification_channel_id = var.monitoring.notification_channel_id

  depends_on = [
    module.gke-cluster
  ]
}

resource "google_compute_firewall" "bastion-egress" {
  // Egress to Kubernetes API is the only allowed traffic
  name      = "bastion-egress"
  network   = module.network.network_name
  direction = "EGRESS"

  destination_ranges = ["${module.gke-cluster.cluster_endpoint}/32"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  target_tags = ["bastion"]

  depends_on = [
    module.network,
    module.gke-cluster
  ]
}

# GKE cluster setup.
module "gke-cluster" {
  source = "../gke_cluster"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network                       = module.network.network_self_link
  subnetwork                    = module.network.subnetwork_self_link
  cluster_secondary_range_name  = module.network.secondary_ip_range.0.range_name
  services_secondary_range_name = module.network.secondary_ip_range.1.range_name

  bastion_ip_address = module.bastion.ip_address

  depends_on = [
    module.network,
  ]
}

// MYSQL
module "mysql" {
  source = "../mysql"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name

  network = module.network.network_self_link

  depends_on = [
    module.network,
    module.gke-cluster
  ]
}

// Cluster policies setup.
module "policy_bindings" {
  source = "../policy_bindings"

  region     = var.region
  project_id = var.project_id

  cluster_name = var.cluster_name
  github_repo  = var.github_repo

  depends_on = [
    module.network
  ]
}


// Rekor
module "rekor" {
  source = "../rekor"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  // Redis
  network = module.network.network_self_link

  // KMS
  kms_keyring  = "rekor-keyring"
  kms_location = "global"
  kms_key_name = "rekor-key"

  // Storage
  attestation_bucket = var.attestation_bucket

  depends_on = [
    module.network,
    module.gke-cluster
  ]
}

// Fulcio
module "fulcio" {
  source = "../fulcio"

  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  // Certificate authority
  ca_pool_name = var.ca_pool_name


  depends_on = [
    module.gke-cluster,
    module.network
  ]
}
