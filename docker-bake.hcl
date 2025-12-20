group "default" {
  targets = ["compass-runtime"]
}

target "actions-runner" {
  context    = "actions-runner"
  dockerfile = "Dockerfile"
  tags       = ["fengheai/actions-runner"]
}

target "compass-runtime" {
  context    = "compass-runtime"
  dockerfile = "Dockerfile"
  tags       = ["fengheai/compass-runtime"]
}
