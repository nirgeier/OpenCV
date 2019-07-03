docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q) 
docker build -t opencv .
docker run -it -p 5901:5901 -p 6901:6901 opencv bash