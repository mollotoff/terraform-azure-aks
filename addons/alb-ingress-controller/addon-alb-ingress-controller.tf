data "kubectl_filename_list" "alb-ingress-controller" {
    pattern = "../addons/alb-ingress-controller/*.yaml"
}

resource "kubectl_manifest" "alb-ingress-controller" {
    count = length(data.kubectl_filename_list.alb-ingress-controller.matches)
    yaml_body = file(element(data.kubectl_filename_list.alb-ingress-controller.matches, count.index))
}
