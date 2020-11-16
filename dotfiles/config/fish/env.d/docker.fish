function dockerclean
    docker ps -a | grep Exit | awk '{print $1}' | xargs docker rm -f
    docker images | grep none | awk '{print $3}' | xargs docker rmi
end
