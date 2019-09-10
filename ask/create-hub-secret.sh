read -p 'Username: ' username
read -sp 'Password: ' userpwd
echo ""
read -p 'Email   : ' useremail
echo "
Hub url could be https://index.docker.io/v1/"
read -p 'Hub url : ' huburl


kubectl create secret docker-registry docker-hub-credentials --docker-server=$huburl --docker-username=$username --docker-password=$userpwd --docker-email=$useremail 
