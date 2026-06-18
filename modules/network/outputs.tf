output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
  value       = aws_nat_gateway.main.id
}

output "public_subnet_ids" {
  description = "Ordered list of public subnet IDs."
  value       = [for k in sort(keys(aws_subnet.public)) : aws_subnet.public[k].id]
}

output "private_subnet_ids" {
  description = "Ordered list of private subnet IDs."
  value       = [for k in sort(keys(aws_subnet.private)) : aws_subnet.private[k].id]
}

output "public_subnet_map" {
  description = "Map of subnet key to public subnet ID (e.g. {a = \"subnet-...\", b = \"subnet-...\"})."
  value       = { for k, s in aws_subnet.public : k => s.id }
}

output "private_subnet_map" {
  description = "Map of subnet key to private subnet ID."
  value       = { for k, s in aws_subnet.private : k => s.id }
}

output "private_route_table_id" {
  description = "ID of the private route table. Pass to modules that need to add endpoint routes."
  value       = aws_route_table.private.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}
