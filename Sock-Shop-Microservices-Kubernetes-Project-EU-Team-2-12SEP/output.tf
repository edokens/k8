output "Master01_public_ip" {
    value = aws_instance.Master_node[0].public_ip
}
output "Master02_public_ip" {
    value = aws_instance.Master_node[1].public_ip
}
output "Master03_public_ip" {
    value = aws_instance.Master_node[2].public_ip
}
output "Kubenetes-Ansible-Server" {
    value = aws_instance.Kubenetes-Ansible-Server.public_ip
}
