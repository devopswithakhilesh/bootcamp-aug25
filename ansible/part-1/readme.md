# login to ec2 with .pem once 
ssh -i ../ansible.pem ec2-user@52.66.242.55

# install ansibe

brew install ansible 

use os specifi comands

# ansible version
 ansible --version
# ansible syntax check 
ansible-playbook --syntax-check  ansible-playboo.yaml
# ansible playbook run
ansible-playbook -i inventory.ini ansible-playboo.yaml