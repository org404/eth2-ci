# Description
This is an automation tool to pull and run continuous integration testing on prysm using [beacon-fuzz](https://github.com/sigp/beacon-fuzz).

### Pre-requirements
Must have:  
* docker  
* docker-compose  

### Setup
Clone repo and initialize submodules:  
```bash
git clone git@github.com:org404/eth2-ci.git
# initialize
cd eth2-ci
git submodule update --init --recursive
```

Run deployment script:
```bash
./deploy
```

### Recommendation
Since docker image cache might take a lot of space, you might want consider purging image cache using docker and crontab.
For that simply type following command to open crontab config file:
```bash
crontab -e
```
Then, prepend following to the file and save it.
```
# Purge all docker image cache every 4 hours.
0 */4 * * * docker system prune -f
```
