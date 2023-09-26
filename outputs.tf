output "dev_ip" {
  value = aws_instance.Frontend-Web.public_ip
}