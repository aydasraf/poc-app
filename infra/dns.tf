resource "aws_route53_record" "external" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${local.service_name}-${terraform.workspace}"
  type    = "A"

  alias {
    name                   = data.terraform_remote_state.lb.outputs.url_shortener_lb_name
    zone_id                = data.terraform_remote_state.lb.outputs.url_shortener_lb_zone_id
    evaluate_target_health = true
  }
}

