target=$1

if [ -z $target ]; then
    echo "You must supply an argument (container name)"
    exit 1
fi

# empty target - do nothing
exists=$(docker ps | grep -e "\s$target$")
# but if container exists - stop it
if [ "$exists" ]; then
    docker stop $target
    echo -e removed "$target" container...
else
    echo "container \"$target\" does not exist. skipping..."
fi
