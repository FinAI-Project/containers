group "default" {
  targets = ["compass-runtime"]
}

target "compass-runtime" {
  context    = "compass-runtime"
  dockerfile = "Dockerfile"
  tags       = ["fengheai/compass-runtime"]
}
