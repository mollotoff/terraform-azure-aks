data "kubectl_filename_list" "nginx-ingress-controller" {
    pattern = "../addons/nginx-ingress-controller/*.yaml"
}

resource "kubectl_manifest" "nginx-ingress-controller" {
    count = length(data.kubectl_filename_list.nginx-ingress-controller.matches)
    yaml_body = file(element(data.kubectl_filename_list.nginx-ingress-controller.matches, count.index))
}
