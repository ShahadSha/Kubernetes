read -p "Please enter the namespace : " ns
kubectl create ns $ns

read -p "Enter the name for the user key : " keyname
openssl genrsa -out $keyname.key 2048 #private key creation
openssl req -new -key $keyname.key -out $keyname.csr -subj "/CN=$keyname/O=$ns" #creating certificate signing request (csr)

echo "copy ca.crt & ca.key to the -${PWD} folder-"
read -r -p "Are you sure? [y/N] " ans


if [[ $ans == y ]]; then
    if [ -f "ca.crt" ] && [ -f "ca.key" ]; then  
        read -p 'Enter the validity for the token : ' expirykey
        openssl x509 -req -in $keyname.csr  -CA ca.crt -CAkey ca.key  -CAcreateserial -out $keyname.crt -days $expirykey #sign the key
    else
        echo "the file is not exist"
    fi  
elif [[ $ans == n ]]; then
  echo "Sorry we can't continue with that"
else
        echo "0ops something went wrong !"
fi

#Creating kubeconfig file

read -p 'Enter the kubernetes server url eg: https://192.168.49.2:8443   : ' serverurl
read -p 'Enter the cluster name : ' clustername

echo 'Setting cluster'
kubectl --kubeconfig $keyname.kubeconfig config set-cluster $clustername --server $serverurl --certificate-authority=ca.crt --embed-certs=true

echo 'Setting credentials'
kubectl --kubeconfig $keyname.kubeconfig config set-credentials $keyname --client-certificate $keyname.crt --client-key $keyname.key --embed-certs=true

echo 'Setting context'
kubectl --kubeconfig $keyname.kubeconfig config set-context $keyname-kubernetes --cluster $clustername --namespace $ns --user $keyname

echo 'using context'
kubectl --kubeconfig $keyname.kubeconfig config use-context $keyname-kubernetes