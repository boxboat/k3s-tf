output "dns" {
  value = aws_lb.this.dns_name
}

output "port" {
  value = aws_lb_target_group.server.port
}
