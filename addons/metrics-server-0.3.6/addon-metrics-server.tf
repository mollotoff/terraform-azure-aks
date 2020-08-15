data "kubectl_filename_list" "metrics-server" {
    pattern = "../addons/metrics-server-0.3.6/deploy/*.yaml"
    
}

resource "kubectl_manifest" "metrics-server" {
    count = length(data.kubectl_filename_list.metrics-server.matches)
    yaml_body = file(element(data.kubectl_filename_list.metrics-server.matches, count.index))
}
