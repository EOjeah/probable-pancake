output "webserver-public-ip" {
  value = "http://${aws_instance.webserver-1.public_ip}"
}
