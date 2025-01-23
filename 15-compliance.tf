#Outputs to demonstrate syslog compliance

output "tokyo_syslog_nlb_dns" {
value       = aws_lb.tokyo_syslog_nlb.dns_name
description = "DNS name of the Syslog NLB in Tokyo"
}

output "tokyo_syslog_vpc_routes" {
value = aws_route_table.tokyo-private.route[*].cidr_block
description = "Route table entries for Tokyo private subnet containing syslog server"
}

output "tokyo_syslog_security_rules" {
value = aws_security_group.tokyo_syslog_sg.ingress[*].cidr_blocks
description = "Allowed CIDR blocks for syslog ingress"
}